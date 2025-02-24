defmodule Chat.DataCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Chat.Repo
      import Ecto
      import Ecto.Query
      import Chat.DataCase
    end
  end

  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Chat.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
    :ok
  end
end
