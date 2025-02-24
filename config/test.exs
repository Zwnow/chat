import Config

config :chat, Chat.Repo,
  database: "chat_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  loggers: [{Ecto.LogEntry, :log, [:info]}],
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 30

config :chat, ecto_repos: [Chat.Repo]

config :logger, level: :error

