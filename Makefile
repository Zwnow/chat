services:
	sudo docker-compose up --build | grep -E 'websocket-service-1|chat-service-1'

db:
	sudo docker exec -it chat-mongo-1 mongosh
