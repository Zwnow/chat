package models

import "github.com/jinzhu/gorm"

type User struct {
	gorm.Model
	Username         string `json:"username"`
	Email            string `json:"email"`
	Password         string `json:"password"`
	VerificationCode string `json:"verification_code"`
	Verified         bool   `json:"verified"`
}
