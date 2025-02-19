package main

import (
	"fmt"
	"log"
	"net/http"

	"github.com/Zwnow/websocket_service/handler"
)

func main() {
	http.HandleFunc("/ws", handler.HandleConnection)

	fmt.Println("WebSocket Server started on :8082")
	log.Fatal(http.ListenAndServe(":8082", nil))
}
