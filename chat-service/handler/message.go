package handler

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"

	"github.com/Zwnow/chat_service/db"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Message struct {
	ID         primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	ChatroomID string             `json:"chatroom_id" bson:"chatroom_id"`
	SenderID   string             `json:"user_id" bson:"user_id"`
	Content    string             `json:"content" bson:"content"`
	Timestamp  time.Time          `json:"timestamp" bson:"timestamp"`
}

type Client struct {
	Username string
	Channel  chan Message
}

var (
	chatroomClients = make(map[string]map[string]*Client)
	mu              sync.Mutex
)

func MessageStreamHandler(c *gin.Context) {
	room := c.Param("chatroom")

	c.Header("Content-Type", "text/event-stream")
	c.Header("Cache-Control", "no-cache")
	c.Header("Connection", "keep-alive")
	c.Header("Transfer-Encoding", "chunked")

	token := c.Request.URL.Query().Get("token")
	if token == "" {
		log.Println("Token empty")
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request payload"})
		return
	}

	user, err := getUserIDFromToken(token)
	if err != nil {
		log.Println(err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not get user"})
		return
	}

	mu.Lock()
	if chatroomClients[room] == nil {
		chatroomClients[room] = make(map[string]*Client)
	}

	if oldClient, exists := chatroomClients[room][user.Username]; exists {
		close(oldClient.Channel)
		delete(chatroomClients[room], user.Username)
	}

	client := &Client{
		Username: user.Username,
		Channel:  make(chan Message),
	}

	chatroomClients[room][user.Username] = client
	mu.Unlock()

	flusher, ok := c.Writer.(http.Flusher)
	if !ok {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Streaming unsupported"})
		return
	}

	fmt.Fprintf(c.Writer, "data: %s\n\n", `{"status":"connected"}`)
	flusher.Flush()

	defer func() {
		mu.Lock()
		delete(chatroomClients[room], user.Username)
		mu.Unlock()
		close(client.Channel)
		log.Println("Client disconnected from chatroom:", room)
	}()

	ticker := time.NewTicker(30 * time.Second)
	defer ticker.Stop()
	for {
		select {
		case <-c.Request.Context().Done():
			return
		case msg := <-client.Channel:
			content := struct {
				Content   string    `json:"content"`
				UserID    string    `json:"user_id"`
				Timestamp time.Time `json:"timestamp"`
			}{
				Content:   msg.Content,
				UserID:    msg.SenderID,
				Timestamp: msg.Timestamp,
			}
			jsonMsg, _ := json.Marshal(content)
			fmt.Fprintf(c.Writer, "data: %s\n\n", jsonMsg)
			flusher.Flush()
		case <-ticker.C:
			fmt.Fprintf(c.Writer, ":\n\n")
			flusher.Flush()
		}
	}
}

func StoreMessage(c *gin.Context) {
	var msg Message

	userID := c.Request.Header.Get("X-User-ID")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request payload"})
		return
	}

	room, _ := c.Params.Get("chatroom")
	if room == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request payload"})
		return
	}

	var request struct {
		Content string `json:"content"`
	}
	if err := c.ShouldBindJSON(&request); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	msg.SenderID = userID
	msg.ChatroomID = room
	msg.Content = request.Content
	msg.Timestamp = time.Now()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := db.MessageCollection.InsertOne(ctx, msg)
	if err != nil {
		log.Println("Database insert error:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save message"})
		return
	}

	mu.Lock()
	for _, client := range chatroomClients[msg.ChatroomID] {
		client.Channel <- msg
	}
	mu.Unlock()

	c.JSON(http.StatusOK, gin.H{"status": "Message stored"})
}

type localUser struct {
	UserID   uint   `json:"user_id"`
	Username string `json:"username"`
}

func getUserIDFromToken(token string) (localUser, error) {
	resp, err := http.Get(fmt.Sprintf("http://user-service:8080/%s", token))
	if err != nil {
		return localUser{}, err
	}
	defer resp.Body.Close()

	var data localUser

	err = json.NewDecoder(resp.Body).Decode(&data)
	if err != nil {
		return localUser{}, err
	}

	return data, nil
}
