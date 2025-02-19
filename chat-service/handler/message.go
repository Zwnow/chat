package handler

import (
	"net/http"
	"time"

	"github.com/Zwnow/chat_service/db"
	"github.com/gin-gonic/gin"
)

type Message struct {
	ID         string    `json:"id" bson:"_id"`
	SenderID   string    `json:"sender_id" bson:"sender_id"`
	ReceiverID string    `json:"receiver_id" bson:"receiver_id"`
	Content    string    `json:"content" bson:"content"`
	Timestamp  time.Time `json:"timestamp" bson:"timestamp"`
}

func StoreMessage(c *gin.Context) {
	var msg Message
	if err := c.ShouldBindJSON(&msg); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	msg.Timestamp = time.Now()

	_, err := db.MessageCollection.InsertOne(c, msg)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save message"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "Message stored"})
}
