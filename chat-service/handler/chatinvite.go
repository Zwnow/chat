package handler

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"

	"github.com/Zwnow/chat_service/db"
	"github.com/gin-gonic/gin"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

type ChatInvite struct {
	ID           primitive.ObjectID `json:"id" bson:"_id,omitempty"`
	ChatroomID   string             `json:"chatroom" bson:"chatroom"`
	FromUserID   int64              `json:"from_user_id" bson:"from_user_id"`
	FromUserName string             `json:"from_user_name" bson:"from_user_name"`
	ToUserID     int64              `json:"to_user_id" bson:"to_user_id"`
	ToUserName   string             `json:"to_user_name" bson:"to_user_name"`
	Timestamp    time.Time          `json:"timestamp" bson:"timestamp"`
}

type userLocal struct {
	ID       uint   `json:"user_id"`
	Username string `json:"username"`
}

func StoreChatInvite(c *gin.Context) {
	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save chatroom, no user ID"})
		return
	}

	var requestData struct {
		ToUserName string `json:"to_user_name"`
		Chatroom   string `json:"chatroom"`
	}

	if err := c.ShouldBindJSON(&requestData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request payload"})
		return
	}

	toUser, err := GetUserByName(requestData.ToUserName)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not find user by name"})
		return
	}

	fromUser, err := GetUser(userID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not find user by id"})
		return
	}

	err = checkUserPair(toUser.ID, fromUser.ID)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invite already sent"})
		return
	}

	if toUser.ID == fromUser.ID {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Can't invite yourself"})
		return
	}

	var chatInvite ChatInvite
	chatInvite.ToUserName = toUser.Username
	chatInvite.ToUserID = int64(toUser.ID)
	chatInvite.FromUserName = fromUser.Username
	chatInvite.FromUserID = int64(fromUser.ID)
	chatInvite.ChatroomID = requestData.Chatroom
	chatInvite.Timestamp = time.Now()

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	_, err = db.ChatInviteCollection.InsertOne(ctx, chatInvite)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to store invite"})
		return
	}

	c.Status(http.StatusOK)
}

func GetChatInvites(c *gin.Context) {
	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request payload"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	id, err := strconv.ParseInt(userID, 10, 64)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch invites"})
		return
	}

	filter := bson.D{{Key: "to_user_id", Value: id}}
	cursor, err := db.ChatInviteCollection.Find(ctx, filter)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch invites"})
		return
	}
	defer cursor.Close(ctx)

	var invites []ChatInvite
	if err = cursor.All(ctx, &invites); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "failed to fetch invites"})
		return
	}

	c.JSON(http.StatusOK, gin.H{"invites": invites})
}

func AnswerChatInvite(c *gin.Context) {
	userID := c.GetHeader("X-User-ID")
	if userID == "" {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save chatroom, no user ID"})
		return
	}

	var requestData struct {
		InviteID   string `json:"invite_id"`
		ChatroomID string `json:"chatroom_id"`
		Result     bool   `json:"result"`
	}

	if err := c.ShouldBindJSON(&requestData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "Invalid request payload"})
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	primitiveID, err := primitive.ObjectIDFromHex(requestData.ChatroomID)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse chatroom id"})
		return
	}

	// Find Chatroom
	var origRoom Chatroom
	filter := bson.D{{Key: "_id", Value: primitiveID}}
	err = db.ChatroomCollection.FindOne(ctx, filter).Decode(&origRoom)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to find chatroom"})
		return
	}

	if requestData.Result {
		// Create chatroom
		var room JoinedChatroom
		room.UserID = userID
		room.Name = origRoom.Name
		room.Timestamp = origRoom.Timestamp
		room.ChatroomID = requestData.ChatroomID

		_, err := db.JoinedRoomsCollection.InsertOne(ctx, room)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to create chatroom"})
			return
		}

		c.Status(http.StatusOK)
	} else {
		// Delete invite
		primitiveInviteID, err := primitive.ObjectIDFromHex(requestData.InviteID)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to parse invite id"})
			return
		}

		filter = bson.D{{Key: "_id", Value: primitiveInviteID}}
		_, err = db.ChatInviteCollection.DeleteOne(ctx, filter)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to delete invite"})
			return
		}

		c.Status(http.StatusOK)
	}
}

func GetUserByName(username string) (userLocal, error) {
	resp, err := http.Get(fmt.Sprintf("http://user-service:8080/user/name/%s", username))
	if err != nil || resp.StatusCode != 200 {
		log.Println(err)
		return userLocal{}, errors.New("could not get user by name")
	}
	defer resp.Body.Close()

	var data userLocal
	err = json.NewDecoder(resp.Body).Decode(&data)
	if err != nil {
		log.Println(err)
		return userLocal{}, err
	}

	log.Printf("%+v", data)

	return data, nil
}

func GetUser(userID string) (userLocal, error) {
	resp, err := http.Get(fmt.Sprintf("http://user-service:8080/user/%s", userID))
	if err != nil {
		return userLocal{}, err
	}
	defer resp.Body.Close()

	var data userLocal
	err = json.NewDecoder(resp.Body).Decode(&data)
	if err != nil {
		return userLocal{}, err
	}

	return data, nil
}

func checkUserPair(toID, fromID uint) error {
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	filter := bson.D{
		{Key: "from_user_id", Value: fromID},
		{Key: "to_user_id", Value: toID},
	}

	var chatInvite ChatInvite
	err := db.ChatInviteCollection.FindOne(ctx, filter).Decode(&chatInvite)
	if err == mongo.ErrNoDocuments {
		return nil
	} else {
		return errors.New("invitation check failed")
	}
}
