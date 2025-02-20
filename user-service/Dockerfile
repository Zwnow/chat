FROM golang:1.23-alpine as builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -o user-service .

FROM alpine:latest

COPY --from=builder /app/user-service .
EXPOSE 8080

CMD ["./user-service"]
