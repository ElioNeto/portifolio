#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Railway Infrastructure Provisioning
# RAILWAY_API_TOKEN  = Account Token (GraphQL API)
# RAILWAY_WORKSPACE_ID = Workspace ID (cmd+k > "copy workspace id")
# ============================================================

BLUE='\033[0;34m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
debug(){ echo -e "${YELLOW}[DEBUG]${NC} $*"; }

[ -z "${RAILWAY_API_TOKEN:-}"    ] && fail "RAILWAY_API_TOKEN nao configurado."
[ -z "${RAILWAY_WORKSPACE_ID:-}" ] && fail "RAILWAY_WORKSPACE_ID nao configurado. Abra o Railway, pressione Cmd+K e busque 'copy workspace id'."

PROJECT_NAME="${PROJECT_NAME:-portifolio}"
REPO="${REPO:-ElioNeto/portifolio}"
ENVIRONMENT="production"
RAILWAY_API="https://backboard.railway.app/graphql/v2"
SERVICES=("backend" "frontend-pt" "frontend-en" "frontend-es")

TMP=$(mktemp -d)
trap 'rm -rf $TMP' EXIT

# ---- Helper: Railway GraphQL ----
railway_gql() {
  local PAYLOAD_FILE="$1"
  debug "Payload: $(cat $PAYLOAD_FILE)"
  local RESP
  RESP=$(curl -s -X POST "$RAILWAY_API" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $RAILWAY_API_TOKEN" \
    --data-binary "@$PAYLOAD_FILE")
  debug "Response: $RESP"
  local ERRORS
  ERRORS=$(echo "$RESP" | jq -r 'if .errors then .errors | map(.message) | join(", ") else empty end' 2>/dev/null || echo "")
  if [ -n "$ERRORS" ]; then
    fail "GraphQL error: $ERRORS\nPayload: $(cat $PAYLOAD_FILE)\nResponse: $RESP"
  fi
  echo "$RESP"
}

# ---- Helper: GitHub Variable upsert ----
set_gh_var() {
  local KEY="$1" VALUE="$2"
  log "  GitHub Var: $KEY = $VALUE"
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

# ===========================================================
# 0. Validar token (me so retorna id/name — NAO projects)
# ===========================================================
log "Validando RAILWAY_API_TOKEN..."
jq -n '{"query": "{ me { id name } }"}' > "$TMP/q.json"
ME=$(railway_gql "$TMP/q.json")
ME_NAME=$(echo "$ME" | jq -r '.data.me.name // empty')
[ -z "$ME_NAME" ] && fail "Token invalido. Resposta: $ME"
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
# 2. Buscar ou criar projeto via workspace query
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
# 3. Obter Environment ID do projeto
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
# 4. Criar servicos (idempotente)
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
# 5. Setar variaveis no backend
# ===========================================================
log "Configurando variaveis do backend..."

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

set_railway_var "${SERVICE_IDS[backend]}" "PORT" "8080"
set_railway_var "${SERVICE_IDS[backend]}" "ALLOWED_ORIGINS" "https://portifolio-pt.up.railway.app"

# ===========================================================
# 6. Gravar IDs como GitHub Variables
# ===========================================================
log "Gravando variaveis no GitHub Environment '$ENVIRONMENT'..."
set_gh_var "RAILWAY_WORKSPACE_ID"        "$RAILWAY_WORKSPACE_ID"
set_gh_var "RAILWAY_PROJECT_ID"          "$PROJECT_ID"
set_gh_var "RAILWAY_ENV_ID"              "$ENV_ID"
set_gh_var "RAILWAY_BACKEND_SERVICE"     "${SERVICE_IDS[backend]}"
set_gh_var "RAILWAY_FRONTEND_PT_SERVICE" "${SERVICE_IDS[frontend-pt]}"
set_gh_var "RAILWAY_FRONTEND_EN_SERVICE" "${SERVICE_IDS[frontend-en]}"
set_gh_var "RAILWAY_FRONTEND_ES_SERVICE" "${SERVICE_IDS[frontend-es]}"

if [ -n "${BACKEND_URL_OVERRIDE:-}" ]; then
  set_gh_var "BACKEND_URL" "$BACKEND_URL_OVERRIDE"
else
  warn "BACKEND_URL_OVERRIDE nao informado. Atualize BACKEND_URL apos o primeiro deploy."
fi

# ===========================================================
# 7. Resumo
# ===========================================================
echo ""
echo "=========================================="
ok " INFRA PROVISIONADA COM SUCESSO!"
echo "=========================================="
printf "  %-25s %s\n" "Autenticado:"  "$ME_NAME"
printf "  %-25s %s\n" "Workspace:"   "$RAILWAY_WORKSPACE_ID"
printf "  %-25s %s\n" "Projeto:"     "$PROJECT_NAME ($PROJECT_ID)"
printf "  %-25s %s\n" "Environment:" "$ENV_NAME ($ENV_ID)"
echo ""
for SVC in "${SERVICES[@]}"; do
  printf "  %-22s %s\n" "$SVC:" "${SERVICE_IDS[$SVC]}"
done
echo ""
warn "Proximos passos:"
echo "  1. Rode: Deploy Backend -> Railway"
echo "  2. Rode: Deploy Frontend -> Railway"
echo "  3. Atualize BACKEND_URL com a URL real gerada pelo Railway."
echo ""
