package handler

import (
	"context"
	"log"
	"net/http"
	"time"

	"github.com/Zwnow/chat_service/db"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Chatroom struct {
	ID        primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	Code      string             `json:"code" bson:"code"`
	UserID    string             `json:"user_id" bson:"user_id"`
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

type User struct {
	UserID string `json:"user_id" bson:"user_id"`
}

func GetChatrooms(c *gin.Context) {
	var user User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	filter := bson.D{{"user_id", user.UserID}}
	cursor, err := db.ChatroomCollection.Find(ctx, filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch chatrooms"})
		return
	}

	var chatrooms []Chatroom
	if err = cursor.All(context.TODO(), &chatrooms); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch chatrooms"})
		return
	}
}
