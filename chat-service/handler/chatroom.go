package handler

import (
	"context"
	"encoding/json"
	"fmt"
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
	Timestamp time.Time          `json:"timestamp" bson:"timestamp"`
}

func StoreChatroom(c *gin.Context) {
	claimsJSON := c.GetHeader("X-Claims")
	userID, err := getUserIdFromClaims(claimsJSON)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save chatroom"})
		return
	}

	var chatroom Chatroom

	chatroom.UserID = userID
	chatroom.Timestamp = time.Now()
	if chatroom.ID.IsZero() {
		chatroom.ID = primitive.NewObjectID()
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	log.Printf("%+v", db.ChatroomCollection)

	log.Printf("Trying to insert: %v", chatroom)
	_, err = db.ChatroomCollection.InsertOne(ctx, chatroom)
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
	var user User
	if err := c.ShouldBindJSON(&user); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	filter := bson.D{{Key: "user_id", Value: user.UserID}}
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

func getUserIdFromClaims(claimsJSON string) (string, error) {
	var claims map[string]interface{}
	err := json.Unmarshal([]byte(claimsJSON), &claims)
	if err != nil {
		log.Println(err)
		return "", err
	}

	userID, ok := claims["user_id"].(string)
	if !ok {
		return "", fmt.Errorf("no user id in map")
	}
	return userID, nil
}
