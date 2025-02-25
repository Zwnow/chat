import Config

config :chat, Chat.Repo,
  database: "chat_repo",
  username: "postgres",
  password: "postgres",
  hostname: "localhost"

config :chat, ecto_repos: [Chat.Repo]
config :joken, default_signer: System.fetch_env("JWT_SECRET")

import_config("#{config_env()}.exs")
