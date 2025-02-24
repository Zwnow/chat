import Config

config :chat, Chat.Repo,
  database: "chat_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :chat, ecto_repos: [Chat.Repo]
