package db

import (
	"context"
	"log"

	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

var (
	MessageCollection  *mongo.Collection
	ChatroomCollection *mongo.Collection
)

func Init() {
	clientOptions := options.Client().ApplyURI("mongodb://mongo:27017")
	client, err := mongo.Connect(context.TODO(), clientOptions)
	if err != nil {
		log.Fatal("Failed to connect to MongoDB", err)
	}

	err = client.Ping(context.TODO(), nil)
	if err != nil {
		log.Fatalf("Mongo ping failed: %v", err)
	}

	log.Println("Connected to MongoDB")
	MessageCollection = client.Database("chat_db").Collection("messages")
	MessageCollection = client.Database("chat_db").Collection("chatrooms")
}
