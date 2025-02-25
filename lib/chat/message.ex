defmodule Chat.Message do
  use Ecto.Schema

  schema "messages" do
    field :content, :string
    field :user_id, :integer

    belongs_to :chatroom, Chat.Chatroom

    timestamps()
  end
end
