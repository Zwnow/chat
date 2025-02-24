defmodule Chat.Router do
  use Plug.Router

  plug Plug.Logger
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Hello, world!")
  end

  post "/register" do
    case Chat.User.register_user(conn.body_params) do
      {:ok, _user} -> 
        send_resp(conn, 201, "User registered")
      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end)
        send_resp(conn, 400, Jason.encode!(%{errors: errors}))
      _ ->
        send_resp(conn, 400, "Invalid request payload")
    end
  end

  post "/login" do
    case Chat.User.login_user(conn.body_params) do
      {:ok, token} ->
        send_resp(conn, 200, Jason.encode!(%{token: token}))
      _ ->
        send_resp(conn, 400, "Invalid request payload")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
