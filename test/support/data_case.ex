defmodule Chat.DataCase do
  use ExUnit.CaseTemplate
  use Plug.Test

  using do
    quote do
      alias Chat.Repo
      import Ecto
      import Ecto.Query
      import Chat.DataCase
    end
  end

  setup do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Chat.Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Chat.Repo, {:shared, self()})
    Chat.Repo.delete_all(Chat.User)
    :ok
  end
end
