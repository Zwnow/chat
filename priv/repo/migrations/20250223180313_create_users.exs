defmodule Chat.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :user_name, :string, null: false
      add :email, :string, null: false
      add :password_hash, :string, null: false
      add :verified, :boolean, default: false
      add :verification_code, :string, null: false
      timestamps()
    end

    create unique_index(:users, [:user_name])
    create unique_index(:users, [:email])

    create table(:chatrooms) do
      add :user_id, references(:users)
      add :name, :string, null: false
      timestamps()
    end

    create table(:chatroom_members) do
      add :chatroom_id, :integer, null: false
      add :user_id, :integer, null: false
      timestamps()
    end

    create table(:messages) do
      add :user_id, references(:users)
      add :chatroom_id, references(:chatrooms)
      add :content, :string, null: false
      timestamps()
    end

    create table(:chat_invitations) do
      add :user_id, references(:users)
      add :to_user_id, references(:users)
      add :chatroom, references(:chatrooms)
      timestamps()
    end

    create unique_index(:chat_invitations, [:user_id, :to_user_id])
  end
end
