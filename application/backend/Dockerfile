FROM golang:latest as builder
ARG VERSION=${VERSION}
WORKDIR /app
COPY ./cmd/api ./ ./go.mod ./ ./go.sum ./
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o main ./cmd/api
FROM alpine:latest
ARG VERSION=${VERSION}
WORKDIR /app
COPY --from=builder /app/main .
EXPOSE 8081
ENTRYPOINT ["./main"]