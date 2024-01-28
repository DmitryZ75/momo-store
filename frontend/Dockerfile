FROM node:16 as builder
WORKDIR /app
COPY . .
RUN npm install \
&& npm run build

FROM nginx:latest
WORKDIR /app
RUN addgroup --system frontuser && \
		adduser --system --shell /bin/false --no-create-home --disabled-login --ingroup frontuser frontuser && \
		chown -R frontuser:frontuser /app && chmod -R 755 /app && \
		chown -R frontuser:frontuser /var/cache/nginx && \
	    chown -R frontuser:frontuser /var/log/nginx && \
	    chown -R frontuser:frontuser /etc/nginx/conf.d && \
		touch /var/run/nginx.pid && \
		chown -R frontuser:frontuser /var/run/nginx.pid && \
		mkdir -p /etc/nginx/dhparam && \
		chown frontuser:frontuser /etc/nginx/dhparam
COPY --chown=frontuser:frontuser --from=builder /app/dist/ /momo-store
COPY --chown=frontuser:frontuser --from=builder /app/nginx.conf /etc/nginx/conf.d/default.conf
ENV VUE_APP_API_URL: "backend:8081"
USER frontuser
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]