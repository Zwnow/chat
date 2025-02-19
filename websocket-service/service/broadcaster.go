package service

import (
	"fmt"
	"log"
	"strings"

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

		// Temporary requiring userId as target
		parts := strings.Split(string(message), " ")
		log.Printf("Parts: %v", parts)
		if len(parts) >= 2 {
			receiverID := parts[0]
			log.Printf("ReceiverID: %s", receiverID)
			msg := strings.Join(parts[1:], " ")
			log.Printf("Message: %s", msg)

			if err := db.SaveMessage(userID, receiverID, msg); err != nil {
				log.Println("Error storing message:", err)
			}
			// Temporary requiring userId as target

			BroadcastMessage(userID, receiverID, msg)
		}
	}
}

func BroadcastMessage(senderID, receiverID, message string) {
	conn := db.Connections[receiverID]
	if conn == nil {
		err := db.Connections[senderID].WriteMessage(websocket.TextMessage, []byte("[Error]: Receiver could not be found.\n"))
		if err != nil {
			log.Println("Write error:", err)
			db.Connections[senderID].Close()
			delete(db.Connections, senderID)
		}
	} else {
		err := conn.WriteMessage(websocket.TextMessage, []byte(fmt.Sprintf("[%s]: %s", senderID, message)))
		if err != nil {
			log.Println("Write error:", err)
			conn.Close()
			delete(db.Connections, senderID)
		}
	}
}
