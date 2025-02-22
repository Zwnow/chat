package main

import (
	"fmt"
	"log"

	"github.com/Zwnow/chat_service/db"
	"github.com/Zwnow/chat_service/handler"
	"github.com/gin-gonic/gin"
)

func main() {
	db.Init()

	router := gin.Default()
	router.POST("/api/messages/:chatroom", handler.StoreMessage)
	router.POST("/api/chatroom", handler.StoreChatroom)
	router.GET("/api/chatroom", handler.GetChatrooms)
	router.POST("/api/chatinvite", handler.StoreChatInvite)
	router.GET("/api/chatinvite", handler.GetChatInvites)
	router.POST("/api/chatinvite/answer", handler.AnswerChatInvite)
	router.GET("/stream/:chatroom", handler.MessageStreamHandler)

	// router.GET("/api/:user/:chatroom", handler.GetUserChatroom)

	fmt.Println("Chat Service running on port 8081")
	log.Fatal(router.Run(":8081"))
}
