# Running

Use `docker-compose up --build` to run the services.
If it works you can use `wscat -c ws://localhost:8082/ws?user_id=user1` to connect to a websocket.
Obviously requires wscat

## Services

### Chat Service
The chat service is responsible for storing messages that users have sent.
Currently it only has:
- a `/db/db.go` file, for connecting to the `MongoDB` instance
- a `/handler/message.go` file, for storing `Message` structs in the database
- a `/main.go` file to simply initiate the whole thing

### Websocket Service
The websocket service upgrades requests to a websocket connection. It currently
has:
- a `/main.go` file to initialize the service and handle the requests to `/ws`
- a `/handler/connection.go` file that upgrades the connection, parses a user id and adds the connection to a connection map in `/db/db.go`, after that it starts a subroutine with a `ListenForMessages` handler
- a `/service/broadcaster.go` file that provides a `ListenForMessages` handler. This is started in subroutines, waits for messages, triggers a call to store messages and finally broadcasts the message
- and finally a `db/db.go` file which is responsible to send a http post request to the `chat service` for storing messages

### User Service
The user service is supposed to be responsible for registering and authenticating users. It uses `Postgres` as Database as it's a better fit for structured data than `MongoDB`.

Nginx is configured to first authenticate the request and then forward to the correct recipient.

## Usage
### Usage currently does not work while I implement an auth system
Start up the containers and then use this command to create websocket connections:`wscat -c "ws://localhost/ws?user_id=user1" -H "Authorization: 123" `, adjust the userID for each connection.

Send messages in this format `receiverID message`

## Planned

I have never implemented any of this, I am trying to learn some system design with this project so this 100% does not serve as a good example for how to implement stuff!

- User authentication JWT or OAuth 
- User Service with Go & Postgress
- [x] API Gateway with Nginx
- Service discovery
- Message queue with PubSub
- Caching with redis

