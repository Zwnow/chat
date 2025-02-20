package db

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

type ChatroomConnection struct {
	Conn       *websocket.Conn
	ChatroomID string
}

var Connections = make(map[string]ChatroomConnection)

type Message struct {
	UserID  string `json:"user_id"`
	Content string `json:"content"`
}

func SaveMessage(userID, message string) error {
	messageData := Message{
		UserID:  userID,
		Content: message,
	}

	messageJSON, err := json.Marshal(messageData)
	if err != nil {
		log.Printf("Error marshalling message: %v", err)
		return fmt.Errorf("failed to marshal message: %v", err)
	}

	resp, err := http.Post("http://chat-service:8081/messages", "application/json", bytes.NewBuffer(messageJSON))
	if err != nil {
		log.Printf("Error making HTTP request: %v", err)
		return fmt.Errorf("failed to send message to chat service: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		log.Printf("Message from %s successfully saved: %s", userID, message)
	} else {
		log.Printf("Failed to save message, HTTP status: %d", resp.StatusCode)
		return fmt.Errorf("failed to save message, HTTP status: %d", resp.StatusCode)
	}

	return nil
}
