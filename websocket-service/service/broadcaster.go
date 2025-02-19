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
		log.Println("Got message: ", string(message))

		if err := db.SaveMessage(userID, message); err != nil {
			log.Println("Error storing message:", err)
		}

		log.Println("Broadcasting message: ", string(message))
		BroadcastMessage(userID, string(message))
	}
}

func BroadcastMessage(senderID, message string) {
	for userID, conn := range db.Connections {
		log.Printf("conn: %v, userID: %s", userID, userID)
		if userID != senderID {
			err := conn.WriteMessage(websocket.TextMessage, []byte(message))
			if err != nil {
				log.Println("Write error:", err)
				conn.Close()
				delete(db.Connections, userID)
			}
			log.Printf("Wrote message: %s to userID: %s", string(message), userID)
		}
	}
}
