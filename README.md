# Portfólio — Elio Neto

Personal developer portfolio built with **Angular 17+** (standalone components, `@if`/`@for` control flow) and a **Go** backend, deployed on **Railway**.

## Stack

- **Frontend**: Angular 17+, Angular i18n (PT-BR, EN, ES)
- **Backend**: Go (net/http), REST API
- **Deploy**: Railway (Docker multi-stage)
- **CI/CD**: GitHub Actions → Railway

## Project Structure

```
portifolio/
├── frontend/          # Angular 17+ app
│   ├── src/
│   │   ├── app/
│   │   │   ├── core/          # services, guards, interceptors
│   │   │   ├── shared/        # shared components
│   │   │   ├── features/
│   │   │   │   ├── hero/
│   │   │   │   ├── about/
│   │   │   │   ├── projects/
│   │   │   │   ├── skills/
│   │   │   │   └── contact/
│   │   │   ├── app.component.ts
│   │   │   ├── app.config.ts
│   │   │   └── app.routes.ts
│   │   ├── assets/
│   │   ├── i18n/
│   │   │   ├── messages.pt.xlf
│   │   │   ├── messages.en.xlf
│   │   │   └── messages.es.xlf
│   │   └── environments/
│   ├── angular.json
│   ├── package.json
│   └── Dockerfile
├── backend/           # Go REST API
│   ├── cmd/server/
│   ├── internal/
│   │   ├── handler/
│   │   ├── model/
│   │   └── repository/
│   ├── go.mod
│   └── Dockerfile
├── .github/
│   └── workflows/
│       └── ci.yml
├── railway.toml
├── docker-compose.yml
└── .env.example
```

## Getting Started

```bash
# Backend
cd backend && go run ./cmd/server

# Frontend
cd frontend && npm install && npm start

# Docker
docker-compose up --build
```

## i18n — Supported Languages

| Code | Language   |
|------|------------|
| pt   | Português  |
| en   | English    |
| es   | Español    |

Build with specific locale: `npm run build:pt` / `npm run build:en` / `npm run build:es`
