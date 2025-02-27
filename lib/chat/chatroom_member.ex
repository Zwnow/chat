defmodule Chat.ChatroomMember do
  use Ecto.Schema
  import Ecto.Query

  schema "chatroom_members" do
    field :chatroom_id, :integer
    field :user_id, :integer

    timestamps()
  end

  def create(chatroom_id, user_id) do
    item = %Chat.ChatroomMember{chatroom_id: chatroom_id, user_id: user_id}
    case Chat.Repo.insert(item) do
      {:ok, _ } -> :ok
      {:error, _ } -> :error
    end
  end

  def delete(chatroom_id, user_id) do
    case Chat.ChatroomMember 
      |> Ecto.Query.where([chatroom_id: ^chatroom_id, user_id: ^user_id])
      |> Chat.Repo.delete() do
      {:ok, _ } -> :ok
      {:error, _ } -> :error
    end
  end
end
