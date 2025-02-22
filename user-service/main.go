package main

import (
	"log"

	"github.com/Zwnow/user_service/config"
	"github.com/Zwnow/user_service/handlers"
	"github.com/Zwnow/user_service/services"
	"github.com/gin-gonic/gin"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"

	_ "github.com/lib/pq"
)

func main() {
	config.LoadConfig()
	db, err := gorm.Open(postgres.Open(config.PostgresURL), &gorm.Config{})
	if err != nil {
		log.Fatalf("Could connect to the database: %v", err)
	}

	userService := &services.UserService{DB: db}
	userHandler := &handlers.UserHandler{UserService: userService}

	userService.Migrate()

	router := gin.Default()

	router.POST("/register", userHandler.RegisterUser)
	router.POST("/login", userHandler.LoginUser)
	router.GET("/validate-token", userHandler.AuthenticateUser)
	router.GET("/user/name/:name", userHandler.GetUserByName)
	router.GET("/user/:id", userHandler.GetUserById)
	router.GET("/:token", userHandler.GetUserID)

	router.Run(":8080")
}
