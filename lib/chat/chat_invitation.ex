defmodule Chat.ChatInvitation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "chat_invitations" do
    field :user_id, :integer
    field :to_user_id, :integer
    field :chatroom, :integer
    timestamps()
  end

  def changeset(invitation, attrs) do
    invitation
    |> cast(attrs, [:to_user, :user_id, :chatroom])
    |> validate_required([:to_user, :user_id, :chatroom])
  end

  def create(attrs) do
    changeset = Chat.ChatInvitation.changeset(%Chat.ChatInvitation{}, attrs)
    if changeset.valid? do
      user = Ecto.Changeset.apply_changes(changeset)
      Chat.Repo.insert(user)
      :ok
    else
      {:error, "Invalid request payload"}
    end
  end
end
