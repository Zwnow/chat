defmodule Chat.User do
  use Ecto.Schema

  schema "users" do
    field :user_name, :string
    field :email, :string
    field :password, :string
    field :verified, :boolean
    field :verification_code, :string
    field :created_at, :naive_datetime
  end

  def changeset(user, params \\ []) do
    user
    |>Ecto.Changeset.cast(params, [:user_name, :email, :password, :verification_code])
    |>Ecto.Changeset.validate_required([:user_name, :email, :password, :verification_code])
  end
end
