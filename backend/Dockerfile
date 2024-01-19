FROM golang:1.16-alpine as builder
WORKDIR /build
COPY . .
RUN go mod download
RUN go build -o api ./cmd/api

FROM alpine:3
WORKDIR /app
RUN addgroup --system backuser && \
		adduser -S -s /bin/false -G backuser backuser -D -H && \
		chown -R backuser:backuser /app && \
		chmod -R 755 /app
COPY --chown=backuser:backuser --from=builder /build/api /app/
USER backuser
EXPOSE 8081
ENTRYPOINT ["./api"]