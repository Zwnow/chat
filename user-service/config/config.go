package config

import (
	"log"
    "os"

	"github.com/joho/godotenv"
)

var PostgresURL string

func LoadConfig() {
	err := godotenv.Load("/app/.env")
	if err != nil {
        log.Fatalf("Error loading .env file: %v", err)
	}

    PostgresURL = os.Getenv("POSTGRES_URL")
}
