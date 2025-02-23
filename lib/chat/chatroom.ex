defmodule Chat.Chatroom do
  use Ecto.Schema

  schema "chatrooms" do
    field :user_id, :integer
    field :name, :string

    timestamps()
  end
end
