
FROM node:16.20-alpine3.17 as builder
WORKDIR /app
COPY . .
RUN npx update-browserslist-db@latest $$ npm install && npm run build
FROM nginx:latest
WORKDIR /app
COPY --from=builder /app/dist /usr/share/nginx/html
COPY --from=builder /app/dist /etc/nginx/html/
EXPOSE 80