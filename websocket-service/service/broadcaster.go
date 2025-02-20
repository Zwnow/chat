package service

import (
	"fmt"
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

		err = db.SaveMessage(userID, string(message))
		if err != nil {
			log.Printf("Failed to save message: %v", err)
		}

		BroadcastMessage(userID, string(message))
	}
}

func BroadcastMessage(senderID, message string) {
	conn := db.Connections[senderID]

	for userID, chatroom := range db.Connections {
		if senderID != userID && chatroom.ChatroomID == conn.ChatroomID {
			err := chatroom.Conn.WriteMessage(websocket.TextMessage, []byte(fmt.Sprintf("%s~> %s", senderID, message)))
			if err != nil {
				log.Println("Write error:", err)
				conn.Conn.Close()
				delete(db.Connections, senderID)
			}
		}
	}
}
