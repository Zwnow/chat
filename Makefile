services:
	docker-compose up --build

db:
	docker exec -it chat-mongo-1 mongosh
