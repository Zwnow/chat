package handlers

import (
	"net/http"

	"github.com/Zwnow/user_service/services"
	"github.com/gin-gonic/gin"
)

type UserHandler struct {
	UserService *services.UserService
}

func (uh *UserHandler) RegisterUser(c *gin.Context) {
	var userData struct {
		Username string `json:"username"`
		Email    string `json:"email"`
		Password string `json:"password"`
	}

	if err := c.ShouldBindJSON(&userData); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	user, err := uh.UserService.CreateUser(userData.Username, userData.Email, userData.Password)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": "Could not create user"})
		return
	}

	c.JSON(http.StatusOK, gin.H{
		"user": user,
	})
}
