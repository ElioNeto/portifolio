#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# Railway Infrastructure Provisioning
# Usa a API GraphQL do Railway diretamente (mais confiável em CI)
# Cria: projeto + 4 serviços + variáveis
# Grava IDs no GitHub Environment 'production'
# ============================================================

BLUE='\033[0;34m'; GREEN='\033[0;32m'
YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${BLUE}[INFO]${NC}  $*"; }
ok()   { echo -e "${GREEN}[OK]${NC}    $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC}  $*"; }
fail() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

PROJECT_NAME="${PROJECT_NAME:-portifolio}"
REPO="${REPO:-ElioNeto/portifolio}"
ENVIRONMENT="production"
RAILWAY_API="https://backboard.railway.app/graphql/v2"
SERVICES=("backend" "frontend-pt" "frontend-en" "frontend-es")

# ---- Helper: Railway GraphQL ----
railway_gql() {
  local QUERY="$1"
  curl -s -X POST "$RAILWAY_API" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $RAILWAY_TOKEN" \
    -d "$QUERY"
}

# ---- Helper: GitHub Variable (POST ou PATCH) ----
set_gh_var() {
  local KEY="$1" VALUE="$2"
  log "  GitHub Var: $KEY"
  # Tenta criar; se já existir (422), faz update (PATCH)
  STATUS=$(gh api \
    --method POST \
    -H "Accept: application/vnd.github+json" \
    "/repos/$REPO/environments/$ENVIRONMENT/variables" \
    -f name="$KEY" -f value="$VALUE" \
    --silent -w "%{http_code}" -o /dev/null 2>/dev/null || echo "000")
  if [ "$STATUS" = "409" ] || [ "$STATUS" = "422" ] || [ "$STATUS" = "000" ]; then
    gh api \
      --method PATCH \
      -H "Accept: application/vnd.github+json" \
      "/repos/$REPO/environments/$ENVIRONMENT/variables/$KEY" \
      -f value="$VALUE" --silent 2>/dev/null || warn "Não foi possível atualizar $KEY"
  fi
}

# ===========================================================
# 1. Garantir que o GitHub Environment 'production' existe
# ===========================================================
log "Garantindo environment '$ENVIRONMENT' no GitHub..."
gh api \
  --method PUT \
  -H "Accept: application/vnd.github+json" \
  "/repos/$REPO/environments/$ENVIRONMENT" \
  --silent 2>/dev/null || warn "Environment já existe ou sem permissão."
ok "Environment '$ENVIRONMENT' OK."

# ===========================================================
# 2. Criar ou obter o projeto Railway via GraphQL
# ===========================================================
log "Buscando projeto '$PROJECT_NAME' no Railway..."

ME_RESP=$(railway_gql '{"query":"{ me { projects { edges { node { id name } } } } }"}')
PROJECT_ID=$(echo "$ME_RESP" \
  | jq -r ".data.me.projects.edges[] | select(.node.name==\"$PROJECT_NAME\") | .node.id" 2>/dev/null || echo "")

if [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ]; then
  log "Criando projeto '$PROJECT_NAME'..."
  CREATE_RESP=$(railway_gql "{\"query\":\"mutation { projectCreate(input: { name: \\\"$PROJECT_NAME\\\" }) { id name } }\"")
  PROJECT_ID=$(echo "$CREATE_RESP" | jq -r '.data.projectCreate.id' 2>/dev/null || echo "")
  [ -z "$PROJECT_ID" ] || [ "$PROJECT_ID" = "null" ] && \
    fail "Falha ao criar projeto. Resposta: $CREATE_RESP"
  ok "Projeto criado: $PROJECT_ID"
else
  ok "Projeto já existe: $PROJECT_ID"
fi

# ===========================================================
# 3. Obter o environment ID padrão do projeto (production)
# ===========================================================
log "Buscando environment do projeto..."
ENV_RESP=$(railway_gql "{\"query\":\"{ project(id: \\\"$PROJECT_ID\\\") { environments { edges { node { id name } } } } }\"")
ENV_ID=$(echo "$ENV_RESP" \
  | jq -r '.data.project.environments.edges[0].node.id' 2>/dev/null || echo "")
[ -z "$ENV_ID" ] || [ "$ENV_ID" = "null" ] && fail "Não foi possível obter o Environment ID do projeto."
ok "Environment ID: $ENV_ID"

# ===========================================================
# 4. Criar os serviços
# ===========================================================
declare -A SERVICE_IDS

for SVC in "${SERVICES[@]}"; do
  log "Verificando serviço '$SVC'..."

  SVC_RESP=$(railway_gql "{\"query\":\"{ project(id: \\\"$PROJECT_ID\\\") { services { edges { node { id name } } } } }\"")
  EXISTING_ID=$(echo "$SVC_RESP" \
    | jq -r ".data.project.services.edges[] | select(.node.name==\"$SVC\") | .node.id" 2>/dev/null || echo "")

  if [ -n "$EXISTING_ID" ] && [ "$EXISTING_ID" != "null" ]; then
    ok "Serviço '$SVC' já existe: $EXISTING_ID"
    SERVICE_IDS[$SVC]="$EXISTING_ID"
    continue
  fi

  log "Criando serviço '$SVC'..."
  CREATE_SVC=$(railway_gql "{\"query\":\"mutation { serviceCreate(input: { name: \\\"$SVC\\\", projectId: \\\"$PROJECT_ID\\\" }) { id name } }\"")
  SVC_ID=$(echo "$CREATE_SVC" | jq -r '.data.serviceCreate.id' 2>/dev/null || echo "")
  [ -z "$SVC_ID" ] || [ "$SVC_ID" = "null" ] && \
    fail "Falha ao criar serviço '$SVC'. Resposta: $CREATE_SVC"
  ok "Serviço '$SVC' criado: $SVC_ID"
  SERVICE_IDS[$SVC]="$SVC_ID"
done

# ===========================================================
# 5. Definir variáveis de ambiente no backend via GraphQL
# ===========================================================
log "Configurando variáveis do backend..."

set_railway_var() {
  local SVC_ID="$1" KEY="$2" VALUE="$3"
  railway_gql "{\"query\":\"mutation { variableUpsert(input: { projectId: \\\"$PROJECT_ID\\\", environmentId: \\\"$ENV_ID\\\", serviceId: \\\"$SVC_ID\\\", name: \\\"$KEY\\\", value: \\\"$VALUE\\\" }) }\"}" > /dev/null
}

set_railway_var "${SERVICE_IDS[backend]}" "PORT" "8080"
set_railway_var "${SERVICE_IDS[backend]}" "ALLOWED_ORIGINS" "https://portifolio-pt.up.railway.app"
ok "Variáveis do backend configuradas."

# ===========================================================
# 6. Gravar IDs como GitHub Variables
# ===========================================================
log "Gravando variáveis no GitHub Environment '$ENVIRONMENT'..."

set_gh_var "RAILWAY_PROJECT_ID"          "$PROJECT_ID"
set_gh_var "RAILWAY_ENV_ID"              "$ENV_ID"
set_gh_var "RAILWAY_BACKEND_SERVICE"     "${SERVICE_IDS[backend]}"
set_gh_var "RAILWAY_FRONTEND_PT_SERVICE" "${SERVICE_IDS[frontend-pt]}"
set_gh_var "RAILWAY_FRONTEND_EN_SERVICE" "${SERVICE_IDS[frontend-en]}"
set_gh_var "RAILWAY_FRONTEND_ES_SERVICE" "${SERVICE_IDS[frontend-es]}"

if [ -n "${BACKEND_URL_OVERRIDE:-}" ]; then
  set_gh_var "BACKEND_URL" "$BACKEND_URL_OVERRIDE"
else
  warn "BACKEND_URL_OVERRIDE não informado. Atualize BACKEND_URL manualmente após o primeiro deploy."
fi

# ===========================================================
# 7. Resumo
# ===========================================================
echo ""
echo "=========================================="
ok " INFRA PROVISIONADA COM SUCESSO!"
echo "=========================================="
echo ""
printf "  %-25s %s\n" "Projeto:"  "$PROJECT_NAME ($PROJECT_ID)"
printf "  %-25s %s\n" "Environment:" "$ENV_ID"
echo ""
for SVC in "${SERVICES[@]}"; do
  printf "  %-20s %s\n" "$SVC:" "${SERVICE_IDS[$SVC]}"
done
echo ""
warn "Próximos passos:"
echo "  1. Verifique as variáveis em:"
echo "     https://github.com/$REPO/settings/environments"
echo "  2. Rode o workflow: Deploy Backend → Railway"
echo "  3. Rode o workflow: Deploy Frontend → Railway"
echo "  4. Atualize BACKEND_URL com a URL real gerada pelo Railway."
echo ""
