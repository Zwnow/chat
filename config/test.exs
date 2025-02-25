import Config

config :chat, Chat.Repo,
  database: "chat_dev",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  loggers: [{Ecto.LogEntry, :log, [:info]}],
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :chat, ecto_repos: [Chat.Repo]

config :joken, default_signer: System.fetch_env("JWT_SECRET")

config :logger, level: :error
