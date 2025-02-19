FROM golang:1.23-alpine as builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o websocket-service .

FROM alpine:latest

COPY --from=builder /app/websocket-service .
EXPOSE 8082

CMD ["./websocket-service"]
