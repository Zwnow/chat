package handler

import (
	"log"
	"net/http"

	"github.com/Zwnow/websocket_service/db"
	"github.com/Zwnow/websocket_service/service"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

func HandleConnection(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("Upgrade failed:", err)
		return
	}
	defer conn.Close()

	userID := r.URL.Query().Get("user_id")
	if userID == "" {
		log.Println("User ID not provided")
		return
	}

	db.Connections[userID] = conn
	log.Printf("User %s connected\n", userID)

	go service.ListenForMessages(conn, userID)

	select {}
}
