#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Railway Infrastructure Provisioning
# RAILWAY_API_TOKEN    = Account Token (GraphQL API)
# RAILWAY_WORKSPACE_ID = Workspace ID (cmd+k > "copy workspace id")
# ============================================================

BLUE='\033[0;34m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

[ -z "${RAILWAY_API_TOKEN:-}"    ] && fail "RAILWAY_API_TOKEN nao configurado."
[ -z "${RAILWAY_WORKSPACE_ID:-}" ] && fail "RAILWAY_WORKSPACE_ID nao configurado."

PROJECT_NAME="${PROJECT_NAME:-portifolio}"
REPO="${REPO:-ElioNeto/portifolio}"
ENVIRONMENT="production"
RAILWAY_API="https://backboard.railway.com/graphql/v2"
SERVICES=("backend" "frontend-pt" "frontend-en" "frontend-es")

TMP=$(mktemp -d)
trap 'rm -rf $TMP' EXIT

# ---- Helper: Railway GraphQL (robusto) ----
railway_gql() {
  local PAYLOAD_FILE="$1"
  local HTTP_CODE RESP

  # Captura body + HTTP status separadamente
  HTTP_CODE=$(curl -s -o "$TMP/resp_body.txt" -w "%{http_code}" \
    -X POST "$RAILWAY_API" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $RAILWAY_API_TOKEN" \
    --data-binary "@$PAYLOAD_FILE")

  RESP=$(cat "$TMP/resp_body.txt")

  # Falha em qualquer HTTP nao-2xx
  if [[ "$HTTP_CODE" != 2* ]]; then
    fail "Railway API retornou HTTP $HTTP_CODE\nEndpoint: $RAILWAY_API\nResposta:\n$RESP"
  fi

  # Verifica se e JSON valido
  if ! echo "$RESP" | jq empty 2>/dev/null; then
    fail "Railway API retornou resposta nao-JSON (HTTP $HTTP_CODE)\nResposta:\n$RESP"
  fi

  # Verifica erros GraphQL
  local ERRORS
  ERRORS=$(echo "$RESP" | jq -r 'if .errors then .errors | map(.message) | join(", ") else empty end')
  if [ -n "$ERRORS" ]; then
    fail "GraphQL error: $ERRORS\nPayload: $(cat $PAYLOAD_FILE)\nResposta: $RESP"
  fi

  echo "$RESP"
}

# ---- Helper: GitHub Variable upsert ----
set_gh_var() {
  local KEY="$1" VALUE="$2"
  log "  GitHub Var: $KEY"
  gh api --method POST \
    -H "Accept: application/vnd.github+json" \
    "/repos/$REPO/environments/$ENVIRONMENT/variables" \
    -f name="$KEY" -f value="$VALUE" --silent 2>/dev/null || \
  gh api --method PATCH \
    -H "Accept: application/vnd.github+json" \
    "/repos/$REPO/environments/$ENVIRONMENT/variables/$KEY" \
    -f value="$VALUE" --silent 2>/dev/null || \
  warn "Nao foi possivel gravar $KEY"
}

# ---- Helper: Railway variable upsert ----
set_railway_var() {
  local SVC_ID="$1" KEY="$2" VALUE="$3"
  jq -n \
    --arg pid "$PROJECT_ID" --arg eid "$ENV_ID" \
    --arg sid "$SVC_ID"     --arg name "$KEY" --arg value "$VALUE" \
    '{"query": "mutation($pid:String!,$eid:String!,$sid:String!,$name:String!,$value:String!) { variableUpsert(input: { projectId:$pid, environmentId:$eid, serviceId:$sid, name:$name, value:$value }) }",
     "variables": {"pid":$pid,"eid":$eid,"sid":$sid,"name":$name,"value":$value}}' > "$TMP/q.json"
  railway_gql "$TMP/q.json" > /dev/null
  ok "  Var $KEY setada."
}

# ===========================================================
# 0. Validar token
# ===========================================================
log "Validando RAILWAY_API_TOKEN..."
log "Endpoint: $RAILWAY_API"

jq -n '{"query": "{ me { id name } }"}' > "$TMP/q.json"

# Executa direto (sem railway_gql) para ver tudo em caso de falha
HTTP_CODE=$(curl -s -o "$TMP/me_body.txt" -w "%{http_code}" \
  -X POST "$RAILWAY_API" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $RAILWAY_API_TOKEN" \
  --data-binary "@$TMP/q.json")
ME_RAW=$(cat "$TMP/me_body.txt")

log "HTTP Status: $HTTP_CODE"
log "Resposta raw: $ME_RAW"

if [[ "$HTTP_CODE" != 2* ]]; then
  fail "HTTP $HTTP_CODE. O token pode ser invalido ou a URL mudou.\nVerifique: https://railway.com/account/tokens (Account Token)"
fi

if ! echo "$ME_RAW" | jq empty 2>/dev/null; then
  fail "Resposta nao e JSON. Possivel redirect ou pagina de erro HTML."
fi

ME_NAME=$(echo "$ME_RAW" | jq -r '.data.me.name // empty')
if [ -z "$ME_NAME" ]; then
  fail "Token invalido ou sem permissao.\nErros: $(echo $ME_RAW | jq -r '.errors // "nenhum" | tostring')"
fi
ok "Autenticado como: $ME_NAME"

# ===========================================================
# 1. Garantir GitHub Environment
# ===========================================================
log "Garantindo environment '$ENVIRONMENT' no GitHub..."
gh api --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/$REPO/environments/$ENVIRONMENT" \
  --silent 2>/dev/null || warn "Environment ja existe."
ok "GitHub Environment '$ENVIRONMENT' OK."

# ===========================================================
# 2. Buscar ou criar projeto Railway
# ===========================================================
log "Buscando projeto '$PROJECT_NAME' no workspace $RAILWAY_WORKSPACE_ID..."
jq -n --arg wid "$RAILWAY_WORKSPACE_ID" \
  '{"query": "query($wid: String!) { workspace(workspaceId: $wid) { projects { edges { node { id name } } } } }",
    "variables": {"wid": $wid}}' > "$TMP/q.json"
WS_RESP=$(railway_gql "$TMP/q.json")
PROJECT_ID=$(echo "$WS_RESP" \
  | jq -r --arg NAME "$PROJECT_NAME" \
    '.data.workspace.projects.edges[] | select(.node.name == $NAME) | .node.id' 2>/dev/null || echo "")

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then
  log "Criando projeto '$PROJECT_NAME'..."
  jq -n --arg name "$PROJECT_NAME" --arg wid "$RAILWAY_WORKSPACE_ID" \
    '{"query": "mutation($name: String!, $wid: String!) { projectCreate(input: { name: $name, workspaceId: $wid }) { id name } }",
      "variables": {"name": $name, "wid": $wid}}' > "$TMP/q.json"
  CREATE_RESP=$(railway_gql "$TMP/q.json")
  PROJECT_ID=$(echo "$CREATE_RESP" | jq -r '.data.projectCreate.id // empty')
  [ -z "$PROJECT_ID" ] && fail "Falha ao criar projeto. Resposta: $CREATE_RESP"
  ok "Projeto criado: $PROJECT_ID"
else
  ok "Projeto ja existe: $PROJECT_ID"
fi

# ===========================================================
# 3. Obter Environment ID
# ===========================================================
log "Buscando environment do projeto..."
jq -n --arg pid "$PROJECT_ID" \
  '{"query": "query($pid: String!) { project(id: $pid) { environments { edges { node { id name } } } } }",
    "variables": {"pid": $pid}}' > "$TMP/q.json"
ENV_RESP=$(railway_gql "$TMP/q.json")
ENV_ID=$(echo "$ENV_RESP" | jq -r '.data.project.environments.edges[0].node.id // empty')
ENV_NAME=$(echo "$ENV_RESP" | jq -r '.data.project.environments.edges[0].node.name // "production"')
[ -z "$ENV_ID" ] && fail "Nao foi possivel obter Environment ID. Resposta: $ENV_RESP"
ok "Environment Railway: $ENV_NAME ($ENV_ID)"

# ===========================================================
# 4. Criar/garantir servicos
# ===========================================================
declare -A SERVICE_IDS

for SVC in "${SERVICES[@]}"; do
  log "Verificando servico '$SVC'..."
  jq -n --arg pid "$PROJECT_ID" \
    '{"query": "query($pid: String!) { project(id: $pid) { services { edges { node { id name } } } } }",
      "variables": {"pid": $pid}}' > "$TMP/q.json"
  SVC_RESP=$(railway_gql "$TMP/q.json")
  EXISTING_ID=$(echo "$SVC_RESP" \
    | jq -r --arg name "$SVC" \
      '.data.project.services.edges[] | select(.node.name == $name) | .node.id' 2>/dev/null || echo "")

  if [ -n "$EXISTING_ID" ] && [ "$EXISTING_ID" != "null" ]; then
    ok "Servico '$SVC' ja existe: $EXISTING_ID"
    SERVICE_IDS[$SVC]="$EXISTING_ID"
    continue
  fi

  log "Criando servico '$SVC'..."
  jq -n --arg name "$SVC" --arg pid "$PROJECT_ID" \
    '{"query": "mutation($name: String!, $pid: String!) { serviceCreate(input: { name: $name, projectId: $pid }) { id name } }",
      "variables": {"name": $name, "pid": $pid}}' > "$TMP/q.json"
  CREATE_SVC=$(railway_gql "$TMP/q.json")
  SVC_ID=$(echo "$CREATE_SVC" | jq -r '.data.serviceCreate.id // empty')
  [ -z "$SVC_ID" ] && fail "Falha ao criar servico '$SVC'. Resposta: $CREATE_SVC"
  ok "Servico '$SVC' criado: $SVC_ID"
  SERVICE_IDS[$SVC]="$SVC_ID"
done

# ===========================================================
# 5. Provisionar PostgreSQL via Railway CLI
# ===========================================================
log "Verificando plugin PostgreSQL no projeto..."
jq -n --arg pid "$PROJECT_ID" \
  '{"query": "query($pid: String!) { project(id: $pid) { services { edges { node { id name } } } } }",
    "variables": {"pid": $pid}}' > "$TMP/q.json"
SVC_RESP=$(railway_gql "$TMP/q.json")
PG_EXISTS=$(echo "$SVC_RESP" | jq -r '.data.project.services.edges[] | select(.node.name | test("(?i)postgres")) | .node.id' 2>/dev/null || echo "")

if [ -n "$PG_EXISTS" ]; then
  ok "PostgreSQL ja existe no projeto: $PG_EXISTS"
else
  log "Adicionando plugin PostgreSQL via Railway CLI..."
  export RAILWAY_TOKEN="$RAILWAY_API_TOKEN"
  railway link --project "$PROJECT_ID" --environment "$ENV_ID" 2>/dev/null || true
  if railway add --plugin postgresql --project "$PROJECT_ID" --environment "$ENV_ID" 2>/dev/null; then
    ok "PostgreSQL plugin adicionado com sucesso!"
  else
    warn "Nao foi possivel adicionar PostgreSQL via CLI."
    warn "Adicione manualmente: Railway Dashboard -> + New Service -> Database -> PostgreSQL"
    warn "Depois: backend -> Variables -> Add Reference -> DATABASE_URL"
  fi
fi

# ===========================================================
# 6. Variaveis do backend
# ===========================================================
log "Configurando variaveis do backend..."
BACKEND_SVC_ID="${SERVICE_IDS[backend]}"
set_railway_var "$BACKEND_SVC_ID" "PORT" "8080"
set_railway_var "$BACKEND_SVC_ID" "ALLOWED_ORIGINS" "https://portifolio-pt.up.railway.app"

if [ -n "${DATABASE_URL_OVERRIDE:-}" ]; then
  set_railway_var "$BACKEND_SVC_ID" "DATABASE_URL" "$DATABASE_URL_OVERRIDE"
  ok "DATABASE_URL configurada manualmente."
else
  warn "DATABASE_URL sera injetada via Add Reference no dashboard Railway."
fi

# ===========================================================
# 7. GitHub Variables
# ===========================================================
log "Gravando variaveis no GitHub Environment '$ENVIRONMENT'..."
set_gh_var "RAILWAY_WORKSPACE_ID"        "$RAILWAY_WORKSPACE_ID"
set_gh_var "RAILWAY_PROJECT_ID"          "$PROJECT_ID"
set_gh_var "RAILWAY_ENV_ID"              "$ENV_ID"
set_gh_var "RAILWAY_BACKEND_SERVICE"     "${SERVICE_IDS[backend]}"
set_gh_var "RAILWAY_FRONTEND_PT_SERVICE" "${SERVICE_IDS[frontend-pt]}"
set_gh_var "RAILWAY_FRONTEND_EN_SERVICE" "${SERVICE_IDS[frontend-en]}"
set_gh_var "RAILWAY_FRONTEND_ES_SERVICE" "${SERVICE_IDS[frontend-es]}"
[ -n "${BACKEND_URL_OVERRIDE:-}" ] && set_gh_var "BACKEND_URL" "$BACKEND_URL_OVERRIDE" || \
  warn "BACKEND_URL_OVERRIDE nao informado. Atualize BACKEND_URL apos o primeiro deploy."

# ===========================================================
# 8. Resumo
# ===========================================================
echo ""
echo "=========================================="
ok " INFRA PROVISIONADA COM SUCESSO!"
echo "=========================================="
printf "  %-25s %s\n" "Autenticado:"   "$ME_NAME"
printf "  %-25s %s\n" "Workspace:"    "$RAILWAY_WORKSPACE_ID"
printf "  %-25s %s\n" "Projeto:"      "$PROJECT_NAME ($PROJECT_ID)"
printf "  %-25s %s\n" "Environment:"  "$ENV_NAME ($ENV_ID)"
echo ""
for SVC in "${SERVICES[@]}"; do
  printf "  %-22s %s\n" "$SVC:" "${SERVICE_IDS[$SVC]}"
done
echo ""
warn "Proximos passos:"
echo "  1. Se PostgreSQL nao criado: Railway Dashboard -> + New Service -> Database -> PostgreSQL"
echo "  2. backend -> Variables -> Add Reference -> DATABASE_URL"
echo "  3. Deploy Backend -> Railway"
echo "  4. Deploy Frontend -> Railway"
echo "  5. Atualize BACKEND_URL"
echo ""
