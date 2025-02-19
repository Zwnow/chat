services:
	sudo docker-compose up --build | grep -E 'websocket-service-1|chat-service-1'

connect:
	wscat -c ws://localhost:8082/ws?user_id=user1
