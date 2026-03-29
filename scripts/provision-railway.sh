#!/usr/bin/env bash
# provision-railway.sh — cria servicos, PostgreSQL e configura variaveis no Railway.
#
# Pre-requisito: crie o projeto manualmente no dashboard Railway e copie o Project ID.
#   Railway Dashboard -> Projeto -> Settings -> General -> Project ID
#
# Variaveis obrigatorias:
#   RAILWAY_TOKEN       — token da conta (https://railway.app/account/tokens)
#   RAILWAY_PROJECT_ID  — ID do projeto ja criado no Railway
#
# Variaveis opcionais:
#   BACKEND_URL_OVERRIDE   — URL publica do backend (preencha apos o 1o deploy)
#   REPO                   — repositorio GitHub (default: ElioNeto/portifolio)

set -euo pipefail

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[setup]${NC} $*"; }
warn() { echo -e "${YELLOW}[warn]${NC}  $*"; }
fail() { echo -e "${RED}[error]${NC} $*"; exit 1; }

[[ -z "${RAILWAY_TOKEN:-}"      ]] && fail "RAILWAY_TOKEN nao configurado. Gere em: https://railway.app/account/tokens"
[[ -z "${RAILWAY_PROJECT_ID:-}" ]] && fail "RAILWAY_PROJECT_ID nao configurado. Copie em: Railway -> Projeto -> Settings -> General"

REPO="${REPO:-ElioNeto/portifolio}"
ENVIRONMENT="production"
RAILWAY_API="https://backboard.railway.app/graphql/v2"
SERVICES=("backend" "frontend-pt" "frontend-en" "frontend-es")

# Mapeamento servico -> root directory no repo
declare -A SVC_ROOT
SVC_ROOT[backend]="backend"
SVC_ROOT[frontend-pt]="frontend"
SVC_ROOT[frontend-en]="frontend"
SVC_ROOT[frontend-es]="frontend"

# Mapeamento servico -> branch
declare -A SVC_BRANCH
SVC_BRANCH[backend]="main"
SVC_BRANCH[frontend-pt]="main"
SVC_BRANCH[frontend-en]="main"
SVC_BRANCH[frontend-es]="main"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# gql_file <payload_file> — envia payload JSON, retorna resposta parseada
# ---------------------------------------------------------------------------
gql_file() {
  local payload_file="$1"
  local resp_file="$TMP/resp.json"

  local http_code
  http_code=$(curl -s -o "$resp_file" -w "%{http_code}" \
    -H "Authorization: Bearer ${RAILWAY_TOKEN}" \
    -H "Content-Type: application/json" \
    --data-binary "@${payload_file}" \
    "${RAILWAY_API}")

  if [[ "$http_code" != 2* ]]; then
    echo "[error] Railway API HTTP $http_code" >&2
    echo "[debug] Resposta: $(cat $resp_file)" >&2
    exit 1
  fi

  python3 - "$resp_file" <<'PYEOF'
import sys, json
with open(sys.argv[1]) as f:
    try:
        data = json.load(f)
    except Exception as e:
        print(f"[error] Resposta nao-JSON: {e}", file=sys.stderr)
        sys.exit(1)
if 'errors' in data:
    for e in data['errors']:
        print(f"[error] GraphQL: {e.get('message', e)}", file=sys.stderr)
    sys.exit(1)
print(json.dumps(data))
PYEOF
}

# ---------------------------------------------------------------------------
# gql <query_string> — query inline sem variaveis
# ---------------------------------------------------------------------------
gql() {
  local query="$1"
  local pf="$TMP/q.json"
  printf '{"query": %s}' "$query" > "$pf"
  gql_file "$pf"
}

# ---------------------------------------------------------------------------
# Obtem ID de servico pelo nome (vazio se nao existir)
# ---------------------------------------------------------------------------
get_service_id() {
  local name="$1"
  local query
  query=$(printf '"{ project(id: \\"%s\\") { services { edges { node { id name } } } } }"' "${RAILWAY_PROJECT_ID}")
  gql "$query" | python3 -c "
import sys, json
data = json.load(sys.stdin)
edges = data.get('data',{}).get('project',{}).get('services',{}).get('edges',[])
for e in edges:
    if e['node']['name'] == '$name':
        print(e['node']['id'])
        break
"
}

# ---------------------------------------------------------------------------
# Cria servico vazio, retorna novo ID
# ---------------------------------------------------------------------------
create_service() {
  local name="$1"
  local query
  query=$(printf '"mutation { serviceCreate(input: { projectId: \\"%s\\", name: \\"%s\\" }) { id } }"' "${RAILWAY_PROJECT_ID}" "${name}")
  gql "$query" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data['data']['serviceCreate']['id'])
"
}

# ---------------------------------------------------------------------------
# Retorna o primeiro environment ID do projeto
# ---------------------------------------------------------------------------
get_env_id() {
  local query
  query=$(printf '"{ project(id: \\"%s\\") { environments { edges { node { id name } } } } }"' "${RAILWAY_PROJECT_ID}")
  gql "$query" | python3 -c "
import sys, json
data = json.load(sys.stdin)
edges = data.get('data',{}).get('project',{}).get('environments',{}).get('edges',[])
if not edges:
    print('[error] Nenhum environment encontrado', file=sys.stderr)
    sys.exit(1)
print(edges[0]['node']['id'])
"
}

# ---------------------------------------------------------------------------
# Seta variavel no servico via variableUpsert
# ---------------------------------------------------------------------------
set_railway_var() {
  local svc_id="$1" key="$2" value="$3"
  local env_id pf
  env_id=$(get_env_id)
  pf="$TMP/var.json"
  jq -n \
    --arg pid  "${RAILWAY_PROJECT_ID}" \
    --arg eid  "${env_id}" \
    --arg sid  "${svc_id}" \
    --arg name "${key}" \
    --arg val  "${value}" \
    '{
      query: "mutation Upsert($pid:String!,$eid:String!,$sid:String!,$name:String!,$val:String!) { variableUpsert(input:{projectId:$pid,environmentId:$eid,serviceId:$sid,name:$name,value:$val}) }",
      variables: {pid:$pid, eid:$eid, sid:$sid, name:$name, val:$val}
    }' > "$pf"
  gql_file "$pf" > /dev/null
  log "  SET ${key}"
}

# ---------------------------------------------------------------------------
# Linka servico ao GitHub repo
# ---------------------------------------------------------------------------
link_github_repo() {
  local svc_id="$1" root_dir="$2" branch="$3"
  local pf="$TMP/link.json"
  jq -n \
    --arg sid    "${svc_id}" \
    --arg repo   "${REPO}" \
    --arg branch "${branch}" \
    --arg root   "${root_dir}" \
    '{
      query: "mutation Link($sid:String!,$repo:String!,$branch:String!,$root:String!) { serviceGithubRepoConnect(serviceId:$sid, repoName:$repo, branch:$branch, rootDirectory:$root) }",
      variables: {sid:$sid, repo:$repo, branch:$branch, root:$root}
    }' > "$pf"
  gql_file "$pf" > /dev/null
  log "  Linkado: $REPO ($root_dir@$branch)"
}

# ---------------------------------------------------------------------------
# Seta variavel no GitHub Environment
# ---------------------------------------------------------------------------
set_gh_var() {
  local key="$1" value="$2"
  gh api --method POST \
    -H "Accept: application/vnd.github+json" \
    "/repos/${REPO}/environments/${ENVIRONMENT}/variables" \
    -f name="$key" -f value="$value" --silent 2>/dev/null || \
  gh api --method PATCH \
    -H "Accept: application/vnd.github+json" \
    "/repos/${REPO}/environments/${ENVIRONMENT}/variables/${key}" \
    -f value="$value" --silent 2>/dev/null || \
  warn "Nao foi possivel gravar GitHub var: $key"
  log "  GitHub var: $key"
}

# ===========================================================================
# 0. Validar token
# ===========================================================================
log "Validando acesso ao projeto ${RAILWAY_PROJECT_ID}..."
PROJECT_NAME=$(gql "$(printf '"{ project(id: \\"%s\\") { name } }"' "${RAILWAY_PROJECT_ID}")" | \
  python3 -c "import sys,json; print(json.load(sys.stdin)['data']['project']['name'])")
log "Projeto: $PROJECT_NAME"

# ===========================================================================
# 1. Garantir GitHub Environment
# ===========================================================================
log "Garantindo environment '${ENVIRONMENT}' no GitHub..."
gh api --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/${REPO}/environments/${ENVIRONMENT}" \
  --silent 2>/dev/null || warn "Environment ja existe."
log "GitHub Environment '${ENVIRONMENT}' OK."

# ===========================================================================
# 2. Obter Environment ID do projeto
# ===========================================================================
ENV_ID=$(get_env_id)
log "Environment Railway ID: ${ENV_ID}"

# ===========================================================================
# 3. Criar/garantir servicos
# ===========================================================================
declare -A SERVICE_IDS

for svc in "${SERVICES[@]}"; do
  existing=$(get_service_id "$svc")
  if [[ -n "$existing" ]]; then
    warn "Servico '$svc' ja existe: $existing"
    SERVICE_IDS[$svc]="$existing"
  else
    log "Criando servico: $svc"
    new_id=$(create_service "$svc")
    log "Servico '$svc' criado: $new_id"
    SERVICE_IDS[$svc]="$new_id"
  fi
done

# ===========================================================================
# 4. Linkar servicos ao GitHub
# ===========================================================================
log "Linkando servicos ao repositorio GitHub..."
for svc in "${SERVICES[@]}"; do
  log "  Linkando $svc..."
  link_github_repo "${SERVICE_IDS[$svc]}" "${SVC_ROOT[$svc]}" "${SVC_BRANCH[$svc]}" || \
    warn "  Falha ao linkar $svc (pode ja estar linkado ou precisar de autorizacao OAuth)"
done

# ===========================================================================
# 5. Criar PostgreSQL
# ===========================================================================
log "Verificando PostgreSQL no projeto..."
PG_ID=$(get_service_id "Postgres")
if [[ -n "$PG_ID" ]]; then
  warn "PostgreSQL ja existe: $PG_ID"
else
  log "Criando servico PostgreSQL..."
  pf="$TMP/pg.json"
  jq -n \
    --arg pid "${RAILWAY_PROJECT_ID}" \
    '{
      query: "mutation($pid:String!) { serviceCreate(input:{ projectId:$pid, name:\"Postgres\", source:{ image:\"ghcr.io/railwayapp-templates/postgres-ssl:edge\" } }) { id } }",
      variables: {pid:$pid}
    }' > "$pf"
  PG_ID=$(gql_file "$pf" | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(data['data']['serviceCreate']['id'])
")
  log "PostgreSQL criado: $PG_ID"
fi

# Busca DATABASE_URL gerada pelo Postgres e injeta no backend
log "Buscando DATABASE_URL do PostgreSQL..."
pf="$TMP/dburl.json"
jq -n \
  --arg pid "${RAILWAY_PROJECT_ID}" \
  --arg eid "${ENV_ID}" \
  --arg sid "${PG_ID}" \
  '{
    query: "query($pid:String!,$eid:String!,$sid:String!) { variables(projectId:$pid, environmentId:$eid, serviceId:$sid) }",
    variables: {pid:$pid, eid:$eid, sid:$sid}
  }' > "$pf"
DB_VARS=$(gql_file "$pf")
DATABASE_URL=$(echo "$DB_VARS" | python3 -c "
import sys, json
data = json.load(sys.stdin)
vars = data.get('data',{}).get('variables',{})
print(vars.get('DATABASE_URL',''))
")

if [[ -n "$DATABASE_URL" ]]; then
  log "DATABASE_URL encontrada, injetando no backend..."
  set_railway_var "${SERVICE_IDS[backend]}" "DATABASE_URL" "$DATABASE_URL"
else
  warn "DATABASE_URL ainda nao disponivel (Postgres pode estar inicializando)."
  warn "Apos alguns segundos, re-execute o script ou configure manualmente:"
  warn "  backend -> Variables -> Add Reference -> DATABASE_URL"
fi

# ===========================================================================
# 6. Variaveis do backend
# ===========================================================================
log "Configurando variaveis do backend..."
BACKEND_ID="${SERVICE_IDS[backend]}"
set_railway_var "$BACKEND_ID" "PORT"            "8080"
set_railway_var "$BACKEND_ID" "ALLOWED_ORIGINS" "https://portifolio-pt.up.railway.app"

# ===========================================================================
# 7. GitHub Variables
# ===========================================================================
log "Gravando variaveis no GitHub Environment '${ENVIRONMENT}'..."
set_gh_var "RAILWAY_PROJECT_ID"          "${RAILWAY_PROJECT_ID}"
set_gh_var "RAILWAY_ENV_ID"              "${ENV_ID}"
set_gh_var "RAILWAY_BACKEND_SERVICE"     "${SERVICE_IDS[backend]}"
set_gh_var "RAILWAY_FRONTEND_PT_SERVICE" "${SERVICE_IDS[frontend-pt]}"
set_gh_var "RAILWAY_FRONTEND_EN_SERVICE" "${SERVICE_IDS[frontend-en]}"
set_gh_var "RAILWAY_FRONTEND_ES_SERVICE" "${SERVICE_IDS[frontend-es]}"
set_gh_var "RAILWAY_POSTGRES_SERVICE"    "${PG_ID}"
[[ -n "${BACKEND_URL_OVERRIDE:-}" ]] && set_gh_var "BACKEND_URL" "${BACKEND_URL_OVERRIDE}" || \
  warn "BACKEND_URL nao informada. Atualize apos o primeiro deploy."

# ===========================================================================
# 8. Resumo
# ===========================================================================
echo ""
echo "==========================================="
log " INFRA PROVISIONADA COM SUCESSO!"
echo "==========================================="
printf "  %-25s %s\n" "Projeto Railway:" "$PROJECT_NAME"
printf "  %-25s %s\n" "Project ID:"     "${RAILWAY_PROJECT_ID}"
printf "  %-25s %s\n" "Environment ID:" "${ENV_ID}"
printf "  %-25s %s\n" "PostgreSQL ID:"  "${PG_ID}"
echo ""
for svc in "${SERVICES[@]}"; do
  printf "  %-24s %s\n" "${svc}:" "${SERVICE_IDS[$svc]}"
done
echo ""
warn "Proximos passos:"
echo "  1. Se DATABASE_URL nao foi injetada, aguarde ~30s e re-execute o script"
echo "  2. Rode: Deploy Backend -> Railway"
echo "  3. Rode: Deploy Frontend -> Railway"
echo "  4. Atualize BACKEND_URL com a URL publica do backend"
echo ""
