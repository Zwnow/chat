package service

import (
	"log"

	"github.com/Zwnow/websocket_service/db"
	"github.com/gorilla/websocket"
)

func ListenForMessages(conn *websocket.Conn, userID string) {
	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			log.Println("Read error:", err)
			delete(db.Connections, userID)
			break
		}

		if err := db.SaveMessage(userID, message); err != nil {
			log.Println("Error storing message:", err)
		}

		BroadcastMessage(userID, string(message))
	}
}

func BroadcastMessage(senderID, message string) {
	for userID, conn := range db.Connections {
		if userID != senderID {
			err := conn.WriteMessage(websocket.TextMessage, []byte(message))
			if err != nil {
				log.Println("Write error:", err)
				conn.Close()
				delete(db.Connections, userID)
			}
		}
	}
}
