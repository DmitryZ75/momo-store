# build
FROM node:16-alpine3.16 as builder
WORKDIR /app
COPY . .
#RUN npx browserslist@latest --update-db
# RUN npm install && VUE_APP_API_URL=https://momo-store.dmitryz.ru:8081
RUN npm install
RUN npm run build

FROM nginx:alpine-slim
WORKDIR /momo-store
# RUN rm /etc/nginx/conf.d/default.conf/default.conf
COPY  --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf
COPY  --from=builder /app/dist/ /momo-store/
#COPY ./dist/ /momo-store/
ENV VUE_APP_API_URL: "backend:8081"
EXPOSE 80