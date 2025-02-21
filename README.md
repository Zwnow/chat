# Running

Use `docker-compose up --build` to run the services.
If it works you can use `wscat -c ws://localhost:8082/ws?user_id=user1` to connect to a websocket.
Obviously requires wscat

## Services

### Chat Service
The chat service is responsible for storing messages that users have sent and storing chatrooms created by users. It's connected to MongoDB to store data.

### Websocket Service
The websocket service upgrades requests to a websocket connection. Upgrading a connection requires a valid authorization token and a chatroom either created by the user or joined by the user.

### User Service
The user service allows registering and logging in. It also validates tokens.

### Nginx
Nginx is configured to first authenticate the request and then forward to the correct recipient.

## Planned
I have never implemented any of this, I am trying to learn some system design with this project so this 100% does not serve as a good example for how to implement stuff!

- [x] User authentication JWT or OAuth 
- [x] User Service with Go & Postgress
- [x] API Gateway with Nginx
- Service discovery
- Message queue with PubSub
- Caching with redis

## Currently working on
- [x] Joining chatrooms
- Message handling
- [x] Frontend

