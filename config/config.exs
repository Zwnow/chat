import Config

config :chat, Chat.Repo,
  database: "chat_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :chat, ecto_repos: [Chat.Repo]
