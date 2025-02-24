defmodule Chat.User do
  use Ecto.Schema
  import Ecto.{Query, Changeset}

  schema "users" do
    field :user_name, :string
    field :email, :string
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
    |> cast(attrs, [:user_name, :email])
    |> validate_required([:user_name, :email])
    |> unique_constraint([:user_name, :email])
    |> hash_password(attrs)
    |> gen_verification_code()
  end

  def register_user(attrs) do
    %Chat.User{}
    |> Chat.User.changeset(attrs)
    |> Chat.Repo.insert()
  end

  def login_user(attrs) do
    email = Map.get(attrs, "email")
    password = Map.get(attrs, "password")

    if email && password do
      user = Chat.User |> Ecto.Query.where(email: ^email) |> Chat.Repo.one
      if user && Argon2.verify_pass(password, user.password_hash) do
        token = ""
        {:ok, token}
      else
        {:error, "invalid credentials"}
      end
    else
      {:error, "invalid request payload"}
    end
  end

  defp hash_password(changeset, attrs) do
    password = Map.get(attrs, "password")
    if password do
      put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      add_error(changeset, :password, "can not be blank")
    end
  end

  defp gen_verification_code(changeset) do
    code = :crypto.strong_rand_bytes(6)
    |> Base.encode64()
    |> binary_part(0, 6)

    put_change(changeset, :verification_code, code)
  end
end
