package handler

import (
	"encoding/json"
	"fmt"
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

	token := r.URL.Query().Get("token")
	userID, err := db.GetUserFromToken(token)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	chatroom := r.URL.Query().Get("chatroom")
	if chatroom == "" {
		log.Println("Chatroom not provided")
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	if c := db.Connections[userID]; c.Conn != nil {
		log.Println("User already connected")
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	db.Connections[userID] = db.ChatroomConnection{Conn: conn, ChatroomID: chatroom}

	go service.ListenForMessages(conn, userID, chatroom)

	// Keep the connection open
	select {}
}

func getUserIdFromClaims(claimsJSON string) (string, error) {
	var claims map[string]interface{}
	err := json.Unmarshal([]byte(claimsJSON), &claims)
	if err != nil {
		log.Println(err)
		return "", err
	}

	userID, ok := claims["user_id"].(string)
	if !ok {
		return "", fmt.Errorf("no user id in map")
	}
	return userID, nil
}
