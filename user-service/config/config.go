package config

import (
	"os"
)

var PostgresURL string

func LoadConfig() {
	PostgresURL = os.Getenv("POSTGRES_URL")
}
