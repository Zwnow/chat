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

type Chatroom struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Code      string             `json:"code" bson:"code"`
	Receivers []string           `json:"receivers" bson:"receivers"`
	Active    bool               `json:"is_active" bson:"is_active"`
	Timestamp time.Time          `json:"timestamp" bson:"timestamp"`
}

func StoreChatroom(c *gin.Context) {
	var chatroom Chatroom
	if err := c.ShouldBindJSON(&chatroom); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	chatroom.Timestamp = time.Now()
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err := db.ChatroomCollection.InsertOne(ctx, chatroom)
	if err != nil {
		log.Println("Database insert error:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save message"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"error": "Failed to save chatroom"})
}
