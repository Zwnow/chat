FROM golang:1.23-alpine as builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o chat-service .

FROM alpine:latest

COPY --from=builder /app/chat-service .
EXPOSE 8081

CMD ["./chat-service"]
