defmodule Chat.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :user_name, :string
    field :email, :string
    field :password, :string
    field :password_hash, :string
    field :verified, :boolean
    field :verification_code, :string
    timestamps()

    has_many :messages, Chat.Message
    has_many :chatrooms, Chat.Chatroom
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_name, :email, :password])
    |> validate_required([:user_name, :email, :password])
    |> unique_constraint([:user_name, :email])
    |> hash_password()
    |> gen_verification_code()
  end

  def register_user(attrs) do
    %Chat.User{}
    |> Chat.User.changeset(attrs)
    |> Chat.Repo.insert()
  end

  defp hash_password(changeset) do
    if password = get_change(changeset, :password) do
      put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  defp gen_verification_code(changeset) do
    code = :crypto.strong_rand_bytes(6)
    |> Base.encode64()
    |> binary_part(0, 6)

    put_change(changeset, :verification_code, code)
  end
end
