# Project Configuration
- Requires Postgres
--> Repo is where the data is
--> Schema is what the data is

1. Add to deps in mix.exs:
```elixir
defp deps do
    [
        {:ecto_sql, "~> 3.0"},
        {:postgrex, ">= 0.0.0"}
    ]
end
```
2. run `mix deps.get`
3. run `mix ecto.gen.repo -r ProjectName.Repo`
4. add a database config:
```elixir
config :users, ProjectName.Repo,
    database: "users",
    username: "postgres",
    password: "postgres",
    database: "localhost",
```
5. add `lib/projectname/repo.ex`:
```elixir
defmodule ProjectName.Repo do
    use Ecto.Repo,
        otp_app: :projectname,
        adapter: Ecto.Adapters.Postgres
end
```

6. add `ProjectName.Repo` to `lib/projectname/application.ex`:
```elixir
def start(_type, _args) do
    children = [
        ProjectName.Repo,
    ]
```

7. in `config/config.exs` add underneath the config:
`config :projectname, ecto_repos: [ProjectName.Repo]`


# Creating the database
1. run `mix ecto.create`
2. create a migration `mix ecto.gen.migration create_users`
3. edit the migration however u want
4. run `mix ecto.migrate`


# Querying
- Inserting data:
```elixir
user = %ProjectName.User{}
ProjectName.Repo.insert(user)
```
- Data validation can be made with changesets, see docs

- Retrieving data:
```elixir
ProjectName.User |> Ecto.Query.first |> ProjectName.Repo.one
ProjectName.User |> ProjectName.Repo.all
ProjectName.User |> ProjectName.Repo.get(1)
ProjectName.User |> Ecto.Query.where(last_name: "Smith") |> ProjectName.Repo.all
```

- Updating is best done with changesets
- Deleting:
```elixir
user = ProjectName.User |> Ecto.Query.first |> ProjectName.Repo.one
ProjectName.Repo.delete(user)
```
