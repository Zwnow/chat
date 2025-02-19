package db

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"

	"github.com/gorilla/websocket"
)

var Connections = make(map[string]*websocket.Conn)

type Message struct {
	UserID  string `json:"user_id"`
	Message string `json:"message"`
}

func SaveMessage(userID string, message []byte) error {
	messageData := Message{
		UserID:  userID,
		Message: string(message),
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
	log.Printf("%+v", resp)

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		log.Printf("Message from %s successfully saved: %s", userID, message)
	} else {
		log.Printf("Failed to save message, HTTP status: %d", resp.StatusCode)
		return fmt.Errorf("failed to save message, HTTP status: %d", resp.StatusCode)
	}

	return nil
}
