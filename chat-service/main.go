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
	router.POST("/messages", handler.StoreMessage)
	router.POST("/chatroom", handler.StoreChatroom)
	router.GET("/chatroom", handler.GetChatrooms)

	fmt.Println("Chat Service running on port 8081")
	log.Fatal(router.Run(":8081"))
}
