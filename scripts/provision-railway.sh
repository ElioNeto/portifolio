#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Railway Infrastructure Provisioning
# Railway GraphQL API + jq + verbose logging para debug
# ============================================================

BLUE='\033[0;34m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }
debug(){ echo -e "${YELLOW}[DEBUG]${NC} $*"; }

PROJECT_NAME="${PROJECT_NAME:-portifolio}"
REPO="${REPO:-ElioNeto/portifolio}"
ENVIRONMENT="production"
RAILWAY_API="https://backboard.railway.app/graphql/v2"
SERVICES=("backend" "frontend-pt" "frontend-en" "frontend-es")

TMP=$(mktemp -d)
trap 'rm -rf $TMP' EXIT

# ---- Helper: Railway GraphQL ----
# Grava resposta em $TMP/resp.json e retorna o conteudo
railway_gql() {
  local PAYLOAD_FILE="$1"
  debug "Payload: $(cat $PAYLOAD_FILE)"
  local RESP
  RESP=$(curl -s -X POST "$RAILWAY_API" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $RAILWAY_TOKEN" \
    --data-binary "@$PAYLOAD_FILE")
  debug "Response: $RESP"
  # Falha se vier campo 'errors' na resposta GraphQL
  local ERRORS
  ERRORS=$(echo "$RESP" | jq -r '.errors // empty' 2>/dev/null || echo "")
  if [ -n "$ERRORS" ] && [ "$ERRORS" != "null" ]; then
    fail "GraphQL error: $ERRORS"
  fi
  echo "$RESP"
}

# ---- Helper: GitHub Variable upsert ----
set_gh_var() {
  local KEY="$1" VALUE="$2"
  log "  GitHub Var: $KEY = $VALUE"
  gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    "/repos/$REPO/environments/$ENVIRONMENT/variables" \
    -f name="$KEY" -f value="$VALUE" --silent 2>/dev/null || \
  gh api \
    --method PATCH \
    -H "Accept: application/vnd.github+json" \
    "/repos/$REPO/environments/$ENVIRONMENT/variables/$KEY" \
    -f value="$VALUE" --silent 2>/dev/null || \
  warn "Nao foi possivel gravar $KEY"
}

# ===========================================================
# 0. Validar token com whoami
# ===========================================================
log "Validando RAILWAY_TOKEN..."
jq -n '{"query": "{ me { id email name } }"}' > "$TMP/q.json"
ME=$(railway_gql "$TMP/q.json")
ME_EMAIL=$(echo "$ME" | jq -r '.data.me.email // empty')
[ -z "$ME_EMAIL" ] && fail "Token invalido ou sem permissao. Resposta: $ME"
ok "Autenticado como: $ME_EMAIL"

# ===========================================================
# 1. Garantir GitHub Environment
# ===========================================================
log "Garantindo environment '$ENVIRONMENT' no GitHub..."
gh api --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/$REPO/environments/$ENVIRONMENT" \
  --silent 2>/dev/null || warn "Environment ja existe ou sem permissao."
ok "Environment '$ENVIRONMENT' OK."

# ===========================================================
# 2. Buscar ou criar projeto Railway
# ===========================================================
log "Buscando projeto '$PROJECT_NAME' no Railway..."
jq -n '{"query": "{ me { projects { edges { node { id name } } } } }"}' > "$TMP/q.json"
ME_RESP=$(railway_gql "$TMP/q.json")
PROJECT_ID=$(echo "$ME_RESP" \
  | jq -r --arg NAME "$PROJECT_NAME" \
    '.data.me.projects.edges[] | select(.node.name == $NAME) | .node.id' 2>/dev/null || echo "")

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then
  log "Projeto nao encontrado. Criando '$PROJECT_NAME'..."
  jq -n --arg name "$PROJECT_NAME" \
    '{"query": "mutation($name: String!) { projectCreate(input: { name: $name }) { id name } }",
      "variables": {"name": $name}}' > "$TMP/q.json"
  CREATE_RESP=$(railway_gql "$TMP/q.json")
  PROJECT_ID=$(echo "$CREATE_RESP" | jq -r '.data.projectCreate.id // empty')
  [ -z "$PROJECT_ID" ] && fail "Falha ao criar projeto. Resposta completa: $CREATE_RESP"
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
debug "Environments: $(echo $ENV_RESP | jq '.data.project.environments')"
ENV_ID=$(echo "$ENV_RESP" | jq -r '.data.project.environments.edges[0].node.id // empty')
[ -z "$ENV_ID" ] && fail "Nao foi possivel obter Environment ID. Resposta: $ENV_RESP"
ENV_NAME=$(echo "$ENV_RESP" | jq -r '.data.project.environments.edges[0].node.name // "?"')
ok "Environment: $ENV_NAME ($ENV_ID)"

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
# 5. Setar variaveis de ambiente no backend
# ===========================================================
log "Configurando variaveis do backend..."

set_railway_var() {
  local SVC_ID="$1" KEY="$2" VALUE="$3"
  jq -n \
    --arg pid "$PROJECT_ID" \
    --arg eid "$ENV_ID" \
    --arg sid "$SVC_ID" \
    --arg name "$KEY" \
    --arg value "$VALUE" \
    '{"query": "mutation($pid:String!,$eid:String!,$sid:String!,$name:String!,$value:String!) { variableUpsert(input: { projectId:$pid, environmentId:$eid, serviceId:$sid, name:$name, value:$value }) }",
     "variables": {"pid":$pid,"eid":$eid,"sid":$sid,"name":$name,"value":$value}}' > "$TMP/q.json"
  railway_gql "$TMP/q.json" > /dev/null
  ok "  Var $KEY setada no backend."
}

set_railway_var "${SERVICE_IDS[backend]}" "PORT" "8080"
set_railway_var "${SERVICE_IDS[backend]}" "ALLOWED_ORIGINS" "https://portifolio-pt.up.railway.app"

# ===========================================================
# 6. Gravar IDs como GitHub Variables
# ===========================================================
log "Gravando variaveis no GitHub Environment '$ENVIRONMENT'..."
set_gh_var "RAILWAY_PROJECT_ID"          "$PROJECT_ID"
set_gh_var "RAILWAY_ENV_ID"              "$ENV_ID"
set_gh_var "RAILWAY_BACKEND_SERVICE"     "${SERVICE_IDS[backend]}"
set_gh_var "RAILWAY_FRONTEND_PT_SERVICE" "${SERVICE_IDS[frontend-pt]}"
set_gh_var "RAILWAY_FRONTEND_EN_SERVICE" "${SERVICE_IDS[frontend-en]}"
set_gh_var "RAILWAY_FRONTEND_ES_SERVICE" "${SERVICE_IDS[frontend-es]}"

if [ -n "${BACKEND_URL_OVERRIDE:-}" ]; then
  set_gh_var "BACKEND_URL" "$BACKEND_URL_OVERRIDE"
else
  warn "BACKEND_URL_OVERRIDE nao informado — atualize BACKEND_URL apos o primeiro deploy."
fi

# ===========================================================
# 7. Resumo
# ===========================================================
echo ""
echo "=========================================="
ok " INFRA PROVISIONADA COM SUCESSO!"
echo "=========================================="
printf "  %-25s %s\n" "Projeto:"     "$PROJECT_NAME ($PROJECT_ID)"
printf "  %-25s %s\n" "Auth como:"   "$ME_EMAIL"
printf "  %-25s %s\n" "Environment:" "$ENV_NAME ($ENV_ID)"
echo ""
for SVC in "${SERVICES[@]}"; do
  printf "  %-22s %s\n" "$SVC:" "${SERVICE_IDS[$SVC]}"
done
echo ""
warn "Proximos passos:"
echo "  1. https://github.com/$REPO/settings/environments"
echo "  2. Workflow: Deploy Backend -> Railway"
echo "  3. Workflow: Deploy Frontend -> Railway"
echo "  4. Atualize BACKEND_URL com a URL real gerada pelo Railway."
echo ""
