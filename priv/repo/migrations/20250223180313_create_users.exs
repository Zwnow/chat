defmodule Chat.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :user_name, :string
      add :email, :string
      add :password, :string
      add :verified, :boolean
      add :verification_code, :string
      add :created_at, :naive_datetime
    end
  end
end
