defmodule Chat.User do
  use Ecto.Schema

  schema "users" do
    field :user_name, :string
    field :email, :string
    field :password, :string
    field :verified, :boolean
    field :verification_code, :string
    timestamps()

    has_many :messages, Chat.Message
    has_many :chatrooms, Chat.Chatroom
  end
end
