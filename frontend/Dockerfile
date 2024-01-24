# FROM node:16 as builder
# WORKDIR /app
# COPY . .
# RUN npm install \
# && npm run build

# FROM nginx:latest
# WORKDIR /app
# RUN addgroup --system frontuser && \
# 		adduser --system --shell /bin/false --no-create-home --disabled-login --ingroup frontuser frontuser && \
# 		chown -R frontuser:frontuser /app && chmod -R 755 /app && \
# 		chown -R frontuser:frontuser /var/cache/nginx && \
# 	    chown -R frontuser:frontuser /var/log/nginx && \
# 	    chown -R frontuser:frontuser /etc/nginx/conf.d && \
# 		touch /var/run/nginx.pid && \
# 		chown -R frontuser:frontuser /var/run/nginx.pid && \
# 		mkdir -p /etc/nginx/dhparam && \
# 		chown frontuser:frontuser /etc/nginx/dhparam
# COPY --chown=frontuser:frontuser --from=builder /app/dist/ /usr/share/nginx/html/
# COPY --chown=frontuser:frontuser --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf
# ENV VUE_APP_API_URL: "backend:8081"
# USER frontuser
# EXPOSE 80
# CMD ["nginx", "-g", "daemon off;"]



# FROM node:14.17.3-alpine as builder
# # Create app directory
# WORKDIR /usr/src/app
# COPY . .
# RUN npm install && VUE_APP_API_URL=http://backend:8081 npm run build

# FROM nginx:latest
# WORKDIR /usr/share/nginx/html
# COPY --from=builder /usr/src/app/dist .
# RUN touch maintenance_off.html
# WORKDIR /app
# COPY --from=builder /usr/src/app/nginx.tmpl ./nginx.tmpl
# EXPOSE 8080

# build
FROM node:16-alpine3.16 as builder
WORKDIR /app
COPY . .
RUN npm install && VUE_APP_API_URL=http://backend:8081
COPY . .
RUN npm run build

# release
FROM nginx:latest
WORKDIR /app
COPY  --from=builder /app/dist/ /usr/share/nginx/html/
COPY  --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 8080
