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
	UserID    string             `json:"user_id" bson:"user_id"`
	Name      string             `json:"name" bson:"name"`
	Timestamp time.Time          `json:"timestamp" bson:"timestamp"`
}

func StoreChatroom(c *gin.Context) {
	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save chatroom, no user ID"})
		return
	}

	var chatroomData struct {
		Name string `json:"name"`
	}
	if err := c.ShouldBindJSON(&chatroomData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid name"})
		return
	}

	var chatroom Chatroom

	chatroom.UserID = userID
	chatroom.Name = chatroomData.Name
	chatroom.Timestamp = time.Now()
	if chatroom.ID.IsZero() {
		chatroom.ID = primitive.NewObjectID()
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	log.Printf("%+v", db.ChatroomCollection)

	log.Printf("Trying to insert: %v", chatroom)
	_, err := db.ChatroomCollection.InsertOne(ctx, chatroom)
	if err != nil {
		log.Println("Database insert error:", err)
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save chatroom"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "success", "chatroom": chatroom})
}

type User struct {
	UserID string `json:"user_id" bson:"user_id"`
}

func GetChatrooms(c *gin.Context) {
	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request payload"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	filter := bson.D{{Key: "user_id", Value: userID}}
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

	c.JSON(http.StatusOK, gin.H{"chatrooms": chatrooms})
}

/*
func GetUserChatroom(c *gin.Context) {
	userID := c.Param("user")
	chatroomID := c.Param("chatroom")
	if userID == "" || chatroomID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request payload"})
		return
	}

	filter := bson.D{
		{Key: "user_id", Value: userID},
		{Key: "chatroom_id", Value: chatroomID},
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()
	var room Chatroom
	err := db.ChatroomCollection.FindOne(ctx, filter).Decode(&room)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to parse room"})
		return
	}

	c.Status(http.StatusOK)
}
*/
