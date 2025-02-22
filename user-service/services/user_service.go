package services

import (
	"fmt"
	"log"
	"math/rand"

	"github.com/Zwnow/user_service/models"
	"github.com/alexedwards/argon2id"
	"gorm.io/gorm"
)

type UserService struct {
	DB *gorm.DB
}

func hashPassword(password string) (string, error) {
	hash, err := argon2id.CreateHash(password, argon2id.DefaultParams)
	if err != nil {
		return "", err
	}

	return hash, nil
}

func (us *UserService) MatchPassword(password, hash string) (bool, error) {
	return argon2id.ComparePasswordAndHash(password, hash)
}

func generateVerificationCode() string {
	letters := []rune("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")

	b := make([]rune, 8)
	for i := range b {
		b[i] = letters[rand.Intn(len(letters))]
	}

	return string(b)
}

func (us *UserService) CreateUser(username, email, password string) (*models.User, error) {
	// TODO: Implement real verifications
	if len(username) < 4 || len(email) < 6 || len(password) < 8 {
		return nil, fmt.Errorf("invalid request payload")
	}

	hashed, err := hashPassword(password)
	if err != nil {
		return nil, err
	}

	verificationCode := generateVerificationCode()

	user := &models.User{
		Username:         username,
		Email:            email,
		Password:         hashed,
		VerificationCode: verificationCode,
		Verified:         false,
	}

	if err := us.DB.Create(user).Error; err != nil {
		log.Println("Error creating user:", err)
		return nil, err
	}

	return user, nil
}

func (us *UserService) GetUserByEmail(email string) (*models.User, error) {
	user := &models.User{}
	if err := us.DB.Where("email = ?", email).First(user).Error; err != nil {
		log.Println("Error fetching user by mail:", err)
		return nil, err
	}
	return user, nil
}

func (us *UserService) GetUserById(id string) (*models.User, error) {
	user := &models.User{}
	if err := us.DB.Where("id = ?", id).First(user).Error; err != nil {
		log.Println("Error fetching user by id:", err)
		return nil, err
	}
	return user, nil
}

func (us *UserService) GetUserByName(name string) (*models.User, error) {
	user := &models.User{}
	if err := us.DB.Where("username = ?", name).First(user).Error; err != nil {
		log.Println("Error fetching user by name:", err)
		return nil, err
	}
	return user, nil
}

func (us *UserService) Migrate() {
	if err := us.DB.AutoMigrate(&models.User{}); err != nil {
		log.Fatalf("Could not migrate database: %v", err)
	}
}
