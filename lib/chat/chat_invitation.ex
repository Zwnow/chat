defmodule Chat.ChatInvitation do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  @derive {Jason.Encoder, only: [:id, :user_id, :to_user_id, :chatroom]}
  schema "chat_invitations" do
    field :user_id, :integer
    field :to_user_id, :integer
    field :chatroom, :integer
    timestamps()
  end

  def changeset(invitation, attrs) do
    %{"to_user" => name} = attrs
    user = Chat.User |> Ecto.Query.where([user_name: ^name]) |> Chat.Repo.one()
    new_attrs = Map.put(attrs, "to_user_id", user.id)

    invitation
    |> cast(new_attrs, [:to_user_id, :user_id, :chatroom])
    |> validate_required([:to_user_id, :user_id, :chatroom])
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

  def get(user_id) do
    Chat.ChatInvitation |> Ecto.Query.where([to_user_id: ^user_id]) |> Chat.Repo.all()
  end

  def accept_invitation(attrs) do
    if invitation_owner?(attrs) do
      :ok
    else
      {:error, "Not the invitation owner"}
    end
  end

  def decline_invitation(attrs) do
    if invitation_owner?(attrs) do
      :ok
    else
      {:error, "Not the invitation owner"}
    end
  end

  defp invitation_owner?(attrs) do
    IO.inspect(attrs)
    :ok
  end
end
