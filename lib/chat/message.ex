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
        %{id: chatroom_id} = Ecto.Changeset.get_field(message, :chatroom)
        user_id = Ecto.Changeset.get_field(message, :user_id)
        %{user_name: name} = Chat.User |> Chat.Repo.get(user_id)

        broadcast(chatroom_id, "{\"user\": \"#{name}\", \"message\": \"#{content}\"}\n\n")
        :ok
      {:error, err} -> 
        IO.inspect(err)
        {:error, "failed to insert"}
    end
  end

  defp broadcast(chatroom_id, message) do
    Registry.dispatch(Chat.Registry, "#{chatroom_id}", fn entries ->
      for {pid, _} <- entries do
        send(pid, {:message, message})
      end
    end)
  end
end
