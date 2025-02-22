package service

import (
	"fmt"
	"log"

	"github.com/Zwnow/websocket_service/db"
	"github.com/gorilla/websocket"
)

func ListenForMessages(conn *websocket.Conn, userID uint, userName, chatroomID string) {
	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			log.Println("Read error:", err)
			delete(db.Connections, userID)
			break
		}

		log.Println("Received message")

		err = db.SaveMessage(fmt.Sprintf("%d", userID), chatroomID, string(message))
		if err != nil {
			log.Printf("Failed to save message: %v", err)
		}

		BroadcastMessage(userID, userName, string(message))
	}
}

func BroadcastMessage(senderID uint, name, message string) {
	conn := db.Connections[senderID]

	for userID, chatroom := range db.Connections {
		if senderID != userID && chatroom.ChatroomID == conn.ChatroomID {
			log.Println("Broadcasting message")
			err := chatroom.Conn.WriteMessage(websocket.TextMessage, []byte(fmt.Sprintf("%s: %s", name, message)))
			if err != nil {
				log.Println("Write error:", err)
				conn.Conn.Close()
				delete(db.Connections, senderID)
			}
		}
	}
}
