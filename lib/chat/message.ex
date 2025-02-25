defmodule Chat.Message do
  use Ecto.Schema
  import Ecto.Changeset

  schema "messages" do
    field :content, :string
    field :user_id, :integer

    belongs_to :chatroom, Chat.Chatroom, foreign_key: :chatroom_id

    timestamps()
  end

  def changeset(message, attrs) do
    chatroom = Chat.Repo.get(Chat.Chatroom, attrs["chatroom"])

    message
    |> cast(attrs, [:content, :user_id])
    |> put_assoc(:chatroom, chatroom)
    |> validate_required([:content, :user_id, :chatroom])
  end

  def store_message(attrs) do
    message = Chat.Message.changeset(%Chat.Message{}, attrs)
    content = Ecto.Changeset.get_field(message, :content)
    case Chat.Repo.insert(message) do
      {:ok, _} -> 
        chatroom = Ecto.Changeset.get_field(message, :chatroom)
        Chat.ConnectionHandler.broadcast(chatroom.id, content, attrs["user_name"])
        :ok
      {:error, err} -> 
        IO.inspect(err)
        {:error, "failed to insert"}
    end
  end
end
