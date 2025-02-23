defmodule Chat.ChatInvitation do
  use Ecto.Schema

  schema "chat_invitations" do
    field :user_id, :integer
    field :to_user_id, :integer
    field :chatroom, :integer
    timestamps()
  end
end
