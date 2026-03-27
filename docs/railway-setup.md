# Railway Setup Guide

Este documento descreve como configurar o projeto no Railway para que os GitHub Actions funcionem corretamente.

## 1. Criar o projeto no Railway

```bash
# Instale a Railway CLI
npm install -g @railway/cli

# Login
railway login

# Crie o projeto
railway init --name portifolio
```

## 2. Criar os serviços

No painel do Railway (https://railway.app), crie **4 serviços** dentro do projeto:

| Service Name       | Dockerfile                        | Build Arg     |
|--------------------|-----------------------------------|---------------|
| `backend`          | `backend/Dockerfile`              | —             |
| `frontend-pt`      | `frontend/Dockerfile`             | `LOCALE=pt`   |
| `frontend-en`      | `frontend/Dockerfile`             | `LOCALE=en`   |
| `frontend-es`      | `frontend/Dockerfile`             | `LOCALE=es`   |

## 3. Variáveis de ambiente no Railway

### backend
```
PORT=8080
ALLOWED_ORIGINS=https://portifolio-pt.up.railway.app
```

### frontend-pt / en / es
```
NGINX_PORT=80
```

## 4. Gerar o RAILWAY_TOKEN

1. Acesse: https://railway.app/account/tokens
2. Crie um token com nome `github-actions`
3. Copie o valor

## 5. Configurar Secrets e Vars no GitHub

Acesse: `https://github.com/ElioNeto/portifolio/settings/environments`

Crie o environment `production` e adicione:

### Secrets
| Secret               | Valor                        |
|----------------------|------------------------------|
| `RAILWAY_TOKEN`      | Token gerado no passo 4      |

### Variables
| Variable                        | Valor                         |
|---------------------------------|-------------------------------|
| `RAILWAY_BACKEND_SERVICE`       | ID ou nome do service backend |
| `RAILWAY_FRONTEND_PT_SERVICE`   | ID ou nome do frontend-pt     |
| `RAILWAY_FRONTEND_EN_SERVICE`   | ID ou nome do frontend-en     |
| `RAILWAY_FRONTEND_ES_SERVICE`   | ID ou nome do frontend-es     |
| `BACKEND_URL`                   | URL pública do backend        |

> Obtenha os IDs dos serviços via: `railway service list`

## 6. Estrutura final de URLs

| Serviço       | URL Exemplo                              |
|---------------|------------------------------------------|
| backend       | `https://backend.up.railway.app`         |
| frontend-pt   | `https://portifolio.up.railway.app`      |
| frontend-en   | `https://portifolio-en.up.railway.app`   |
| frontend-es   | `https://portifolio-es.up.railway.app`   |

## 7. Fluxo de deploy

```
git push main
    │
    ├──► CI (build + test todos os locales)
    ├──► deploy-backend.yml  (se backend/** mudou)
    └──► deploy-frontend.yml (se frontend/** mudou)
                └─► matrix: [pt, en, es] em paralelo
```
