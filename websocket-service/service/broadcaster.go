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

		BroadcastMessage(userID, string(message))
	}
}

func BroadcastMessage(senderID, message string) {
	conn := db.Connections[senderID]

	for userID, conn := range db.Connections {
	}

	if conn.Conn == nil {
		err := db.Connections[senderID].Conn.WriteMessage(websocket.TextMessage, []byte("[Error]: Failed to send message."))
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
