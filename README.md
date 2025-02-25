# Learning System Design
### A small chat app

# The why
I can write code. That does not mean I can build systems. Especially not large ones.
I want to learn more about system design. So far I have built smaller apps but I need
to get out of my comfort zone and strive for bigger goals.

# The what
I will build a small chat application. For this I am going to use a microservice
architecture orchestrated with `docker`.
For a small chat app, this very much is not the best architecture, but it serves as
a learning project. The full stack I am going to use is this:

- Nginx
- Golang with [Gin](https://gin-gonic.com/) & [Gorilla Websocket](https://github.com/gorilla/websocket)
- MongoDB for storing messages and chatrooms
    - MongoDB is better suited for fast writes, which is important for a chat app
- Postgres for storing userdata

The services I have built so far are:
- User Service, for registration & login as well as validating user tokens
- Chat Service, for creating chatrooms and storage/retrieval of messages
- Websocket Service, for establishing live connections to chatrooms

The frontend will be a simple Vue App with TailwindCSS for styling and Pinia for state management.

# The who
Hey, I'm Sven. I am a software dev, duh. Earlier in my life I used to draw a lot, tried tattooing too.
Originally learned retail but changed careers a few years ago. Started out in ERP development with Business Central & Navision (Microsoft ERP applications) and quickly learned that I liked webdev far more. So I changed into a webdev career.

# About the app
I will document the different parts of the app within their corresponding folders.

