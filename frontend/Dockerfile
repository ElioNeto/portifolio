# ---- Build Stage ----
FROM node:20-alpine AS builder
ARG LOCALE=pt
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build:${LOCALE}

# ---- Serve Stage ----
FROM nginx:alpine
ARG LOCALE=pt
COPY --from=builder /app/dist/portifolio/browser/${LOCALE} /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
