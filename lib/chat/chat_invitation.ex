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
    case user do
      nil -> %Ecto.Changeset{valid?: false}
      _ -> new_attrs = Map.put(attrs, "to_user_id", user.id)
        invitation
        |> cast(new_attrs, [:to_user_id, :user_id, :chatroom])
        |> validate_required([:to_user_id, :user_id, :chatroom])
    end
  end

  def create(attrs) do
    changeset = Chat.ChatInvitation.changeset(%Chat.ChatInvitation{}, attrs)
    if changeset.valid? do
      invitation = Ecto.Changeset.apply_changes(changeset)
      to_user_id = Ecto.Changeset.get_field(changeset, :to_user_id)
      room_id = Ecto.Changeset.get_field(changeset, :chatroom)
      is_member = Chat.ChatroomMember |> Ecto.Query.where([chatroom_id: ^room_id, user_id: ^to_user_id]) |> Chat.Repo.all()
      case Enum.count(is_member) do
        0 -> 
          Chat.Repo.insert(invitation)
          :ok
        _ -> 
          {:error, "Already member"}
      end
    else
      {:error, "Invalid request payload"}
    end
  end

  def get(user_id) do
    Chat.ChatInvitation |> Ecto.Query.where([to_user_id: ^user_id]) |> Chat.Repo.all()
  end

  def accept_invitation(%{"chatroom" => room_id, "invite_id" => invite_id, "user_id" => user_id} = attrs) do
    with true <- invitation_owner?(attrs),
        %Chat.Chatroom{name: _name} <- Chat.Repo.get(Chat.Chatroom, room_id),
        {:ok, _} <- create_chatroom(user_id, room_id),
        invite <- Chat.Repo.get(Chat.ChatInvitation, invite_id),
        {:ok, _} <- Chat.Repo.delete(invite) do
      :ok
    else
      {:error, _} = err -> err
      nil -> {:error, "Room not found"}
    end
  end

  def accept_invitation(_) do
    {:error, "Room not found"}
  end

  defp create_chatroom(user_id, room_id) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    new_room = %Chat.ChatroomMember{chatroom_id: room_id, user_id: user_id, inserted_at: now, updated_at: now}
    Chat.Repo.insert(new_room)
  end

  def decline_invitation(%{"invite_id" => invite_id} = attrs) do
    if invitation_owner?(attrs) do
      Chat.Repo.get(Chat.ChatInvitation, invite_id)
      |> Chat.Repo.delete()
      :ok
    else
      {:error, "Not the invitation owner"}
    end
  end
  def decline_invitation(_) do
    {:error, "Room not found"}
  end



  defp invitation_owner?(%{"chatroom" => _room_id, "invite_id" => invite_id, "user_id" => user_id} = _attrs) do
    invitation = Chat.ChatInvitation
    |> Ecto.Query.where([id: ^invite_id, to_user_id: ^user_id])
    |> Chat.Repo.one()

    if invitation do true else false end
  end
end
