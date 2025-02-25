defmodule Chat.Chatroom do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

  @derive {Jason.Encoder, only: [:id, :user_id, :name, :inserted_at, :updated_at]}
  schema "chatrooms" do
    field :user_id, :integer
    field :name, :string

    timestamps()
  end

  @doc false
  def changeset(changeset, attrs) do
      changeset
      |> cast(attrs, [:name])
      |> validate_required([:name])
  end

  def create_chatroom(attrs, user_id) do
    %Chat.Chatroom{}
    |> changeset(attrs)
    |> put_change(:user_id, user_id)
    |> validate_required([:user_id])
    |> case do
      %Ecto.Changeset{valid?: true} = changeset ->
        Chat.Repo.insert(changeset)
        {:ok, changeset}

      %Ecto.Changeset{valid?: false} = _changeset ->
        {:error, "Invalid request payload"}
    end
  end

  def get_chatrooms(user_id) do
    result = Chat.Chatroom |> Ecto.Query.where(user_id: ^user_id) |> Chat.Repo.all() 
    {:ok, result}
  end
end
