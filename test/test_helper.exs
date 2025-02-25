ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Chat.Repo, :manual)
Code.require_file("support/data_case.ex", __DIR__)
