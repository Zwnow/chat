package handler

import (
	"context"
	"log"
	"net/http"
	"time"

	"github.com/Zwnow/chat_service/db"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Message struct {
	ID         primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	ChatroomID primitive.ObjectID `json:"chatroom_id" bson:"chatroom_id"`
	SenderID   string             `json:"user_id" bson:"user_id"`
	Content    string             `json:"content" bson:"content"`
	Timestamp  time.Time          `json:"timestamp" bson:"timestamp"`
}

func StoreMessage(c *gin.Context) {
	var msg Message
	if err := c.ShouldBindJSON(&msg); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	msg.Timestamp = time.Now()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := db.MessageCollection.InsertOne(ctx, msg)
	if err != nil {
		log.Println("Database insert error:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save message"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"status": "Message stored"})
}
