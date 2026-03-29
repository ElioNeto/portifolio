#!/usr/bin/env bash
# provision-railway.sh — cria servicos e configura variaveis no Railway.
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
#   DATABASE_URL_OVERRIDE  — DATABASE_URL manual (alternativa ao Add Reference)
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

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# ---------------------------------------------------------------------------
# Helper: executa GraphQL, salva resposta em arquivo, parseia com python
# Evita problemas de interpolacao de JSON dentro de strings bash/python.
# ---------------------------------------------------------------------------
gql() {
  local query="$1"
  local resp_file="$TMP/resp.json"

  local http_code
  http_code=$(curl -s -o "$resp_file" -w "%{http_code}" \
    -H "Authorization: Bearer ${RAILWAY_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{\"query\": ${query}}" \
    "${RAILWAY_API}")

  # HTTP nao-2xx: mostra resposta bruta e falha
  if [[ "$http_code" != 2* ]]; then
    echo "[error] Railway API retornou HTTP $http_code" >&2
    echo "[debug] Resposta: $(cat $resp_file)" >&2
    exit 1
  fi

  # Parseia com python lendo do arquivo (sem interpolacao)
  python3 - "$resp_file" <<'PYEOF'
import sys, json
with open(sys.argv[1]) as f:
    try:
        data = json.load(f)
    except Exception as e:
        print(f"[error] Resposta nao-JSON: {e}", file=sys.stderr)
        print(f"[debug] Raw: {f.read()}", file=sys.stderr)
        sys.exit(1)
if 'errors' in data:
    for e in data['errors']:
        print(f"[error] GraphQL: {e.get('message', e)}", file=sys.stderr)
    sys.exit(1)
print(json.dumps(data))
PYEOF
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
    print('[error] Nenhum environment encontrado no projeto', file=sys.stderr)
    sys.exit(1)
print(edges[0]['node']['id'])
"
}

# ---------------------------------------------------------------------------
# Seta variavel no servico
# ---------------------------------------------------------------------------
set_railway_var() {
  local svc_id="$1" key="$2" value="$3"
  local env_id
  env_id=$(get_env_id)
  local mutation
  mutation=$(printf '"mutation { variableCollectionUpsert(input: { projectId: \\"%s\\", environmentId: \\"%s\\", serviceId: \\"%s\\", variables: { \\"%s\\": \\"%s\\" } }) }"' \
    "${RAILWAY_PROJECT_ID}" "${env_id}" "${svc_id}" "${key}" "${value}")
  gql "$mutation" > /dev/null
  log "  SET ${key}"
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
# 0. Validar token acessando o projeto diretamente
#    (me{} falha com team/project tokens — consultamos o projeto direto)
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
# 4. Variaveis do backend
# ===========================================================================
log "Configurando variaveis do backend..."
BACKEND_ID="${SERVICE_IDS[backend]}"

set_railway_var "$BACKEND_ID" "PORT"            "8080"
set_railway_var "$BACKEND_ID" "ALLOWED_ORIGINS" "https://portifolio-pt.up.railway.app"

if [[ -n "${DATABASE_URL_OVERRIDE:-}" ]]; then
  set_railway_var "$BACKEND_ID" "DATABASE_URL" "${DATABASE_URL_OVERRIDE}"
  log "DATABASE_URL configurada manualmente."
else
  warn "DATABASE_URL nao configurada."
  warn "Apos criar o PostgreSQL no Railway:"
  warn "  backend -> Variables -> Add Reference -> DATABASE_URL"
fi

# ===========================================================================
# 5. GitHub Variables
# ===========================================================================
log "Gravando variaveis no GitHub Environment '${ENVIRONMENT}'..."
set_gh_var "RAILWAY_PROJECT_ID"          "${RAILWAY_PROJECT_ID}"
set_gh_var "RAILWAY_ENV_ID"              "${ENV_ID}"
set_gh_var "RAILWAY_BACKEND_SERVICE"     "${SERVICE_IDS[backend]}"
set_gh_var "RAILWAY_FRONTEND_PT_SERVICE" "${SERVICE_IDS[frontend-pt]}"
set_gh_var "RAILWAY_FRONTEND_EN_SERVICE" "${SERVICE_IDS[frontend-en]}"
set_gh_var "RAILWAY_FRONTEND_ES_SERVICE" "${SERVICE_IDS[frontend-es]}"
[[ -n "${BACKEND_URL_OVERRIDE:-}" ]] && set_gh_var "BACKEND_URL" "${BACKEND_URL_OVERRIDE}" || \
  warn "BACKEND_URL nao informada. Atualize apos o primeiro deploy."

# ===========================================================================
# 6. Resumo
# ===========================================================================
echo ""
echo "==========================================="
log " INFRA PROVISIONADA COM SUCESSO!"
echo "==========================================="
printf "  %-25s %s\n" "Projeto Railway:" "$PROJECT_NAME"
printf "  %-25s %s\n" "Project ID:"     "${RAILWAY_PROJECT_ID}"
printf "  %-25s %s\n" "Environment ID:" "${ENV_ID}"
echo ""
for svc in "${SERVICES[@]}"; do
  printf "  %-24s %s\n" "${svc}:" "${SERVICE_IDS[$svc]}"
done
echo ""
warn "Proximos passos:"
echo "  1. No Railway Dashboard, adicione o banco:"
echo "       + New Service -> Database -> PostgreSQL"
echo "  2. Linke ao backend:"
echo "       backend -> Variables -> Add Reference -> DATABASE_URL"
echo "  3. Configure o root directory de cada servico:"
echo "       backend      -> Source -> Root Directory: backend"
echo "       frontend-pt  -> Source -> Root Directory: frontend"
echo "       frontend-en  -> Source -> Root Directory: frontend"
echo "       frontend-es  -> Source -> Root Directory: frontend"
echo "  4. Rode: Deploy Backend -> Railway"
echo "  5. Rode: Deploy Frontend -> Railway"
echo "  6. Atualize BACKEND_URL com a URL publica do backend"
echo ""
