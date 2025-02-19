services:
	sudo docker-compose up --build

connect:
	wscat -c ws://localhost:8082/ws
