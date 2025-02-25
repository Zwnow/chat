defmodule Chat.User do
  use Ecto.Schema
  import Ecto.Query
  import Ecto.Changeset

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
    |> unique_constraint(:email)
    |> unique_constraint(:user_name)
    |> hash_password(attrs)
    |> gen_verification_code()
  end

  def register_user(attrs) do
    changeset = Chat.User.changeset(%Chat.User{}, attrs)
    if changeset.valid? do
      user = Ecto.Changeset.apply_changes(changeset)
      Chat.Repo.insert(user)
      :ok
    else
      {:error, "Invalid request payload"}
    end
  end

  def login_user(attrs) do
    email = Map.get(attrs, "email")
    password = Map.get(attrs, "password")

    if email && password do
      user = Chat.User |> Ecto.Query.where(email: ^email) |> Chat.Repo.one
      if user && Argon2.verify_pass(password, user.password_hash) do
        case Chat.Token.generate_and_sign(%{"id" => user.id}, Chat.Token.env_signer()) do
          {:ok, token, _claims} -> {:ok, token}
          {:error, reason} -> {:error, reason}
        end
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
      if Mix.env() == :test do
        put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password, t_cost: 1))
        |> delete_change(:password)
      else
        put_change(changeset, :password_hash, Argon2.hash_pwd_salt(password))
        |> delete_change(:password)
      end
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
