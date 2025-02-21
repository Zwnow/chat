package db

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
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
	UserID     string `json:"user_id"`
	ChatroomID string `json:"chatroom_id"`
	Content    string `json:"content"`
}

func SaveMessage(userID, chatroomID, message string) error {
	messageData := Message{
		UserID:     userID,
		ChatroomID: chatroomID,
		Content:    message,
	}

	messageJSON, err := json.Marshal(messageData)
	if err != nil {
		log.Printf("Error marshalling message: %v", err)
		return fmt.Errorf("failed to marshal message: %v", err)
	}

	resp, err := http.Post("http://chat-service:8081/api/messages", "application/json", bytes.NewBuffer(messageJSON))
	if err != nil {
		log.Printf("Error making HTTP request: %v", err)
		return fmt.Errorf("failed to send message to chat service: %v", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Printf("Error reading response body: %v", err)
		return fmt.Errorf("failed to read response body: %v", err)
	}

	var resData map[string]interface{}
	err = json.Unmarshal(body, &resData)
	if err != nil {
		log.Printf("Error unmarshalling response body: %v", err)
		return fmt.Errorf("failed to unmarshal response body: %v", err)
	}

	if resp.StatusCode >= 200 && resp.StatusCode < 300 {
		log.Printf("Message from %s successfully saved: %s", userID, message)
	} else {
		log.Printf("Failed to save message, HTTP status: %d, Response: %v", resp.StatusCode, resp)
		return fmt.Errorf("failed to save message, HTTP status: %d", resp.StatusCode)
	}

	return nil
}

func GetUserFromToken(token string) (string, error) {
	resp, err := http.Get(fmt.Sprintf("http://user-service:8080/%s", token))
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	var data struct {
		UserID string `json:"user_id"`
	}
	err = json.NewDecoder(resp.Body).Decode(&data)
	if err != nil {
		return "", err
	} else if data.UserID == "" {
		return "", errors.New("invalid request payload")
	}

	return data.UserID, nil
}

func UserHasChatroom(userID, chatroomID string) error {
	resp, err := http.Get(fmt.Sprintf("http://chat-service:8081/api/%s/%s", userID, chatroomID))
	if err != nil {
		log.Printf("Error making HTTP request: %v", err)
		return fmt.Errorf("failed to send message to chat service: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode == 200 {
		return nil
	} else {
		return fmt.Errorf("user does not have that chatroom")
	}
}
