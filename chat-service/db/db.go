package db

import (
	"context"
	"fmt"
	"log"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var MessageCollection *mongo.Collection

func Init() {
	client, err := mongo.Connect(context.TODO(), options.Client().ApplyURI("mongodb://localhost:27017"))
	if err != nil {
		log.Fatal("Failed to connect to MongoDB", err)
	}
	MessageCollection = client.Database("chat_db").Collection("messages")
	fmt.Println("Connected to MongoDB!")
}
