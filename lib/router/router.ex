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
      :ok -> 
        send_resp(conn, 201, "User registered")
      {:error, message} ->
        send_resp(conn, 400, Jason.encode!(%{errors: message}))
    end
  end

  post "/login" do
    case Chat.User.login_user(conn.body_params) do
      {:ok, token} ->
        send_resp(conn, 200, Jason.encode!(%{token: token}))
      {:error, _reason} ->
        send_resp(conn, 400, "Login failed")
    end
  end

  post "/validate-token" do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case Chat.Token.verify_token(token) do
          {:ok, claims} ->
            conn 
            |> assign(:jwt_claims, claims)
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{message: "Token valid", claims: claims}))
          {:error, _reason} ->
            conn 
            |> put_status(:unauthorized)
            |> put_resp_content_type("application/json")
            |> send_resp(401, Jason.encode!(%{error: "Invalid token"}))
        end
      _ ->
        conn
        |> put_status(:unauthorized)
        |> put_resp_content_type("application/json")
        |> send_resp(401, Jason.encode!(%{error: "Missing or malformed authorization header"}))
    end
  end


  # App
  post "/chatroom" do
    case validate_token(conn) do
      {:ok, claims} -> 
        case Chat.Chatroom.create_chatroom(conn.body_params, claims["id"]) do
          :ok -> send_resp(conn, 201, "Chatroom created")
          {:error, reason} -> send_resp(conn, 400, reason)
        end
        :error -> send_resp(conn, 400, "Invalid request payload")
    end
  end

  get "/chatroom" do
    case validate_token(conn) do
      {:ok, claims} -> 
        {:ok, result} = Chat.Chatroom.get_chatrooms(claims["id"])
        json_response = Jason.encode!(result)
        send_resp(conn, 201, json_response)
      :error -> send_resp(conn, 400, "Failed to authenticate")
    end
  end

  get "/chatroom/:id" do
    case validate_token(conn) do
      {:ok, claims} -> conn =
        conn
        |> put_resp_content_type("text/event-stream")
        |> send_chunked(200)

        Chat.ConnectionHandler.add_connection(id, conn, claims["id"])
        keep_alive(conn, id)
      :error -> send_resp(conn, 400, "Failed to authenticate")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found!")
  end

  defp keep_alive(conn, chatroom_id) do
    Process.sleep(15_000)

    case Plug.Conn.chunk(conn, ":\n\n") do
      {:ok, _} -> keep_alive(conn, chatroom_id)
      {:error, _} -> Chat.ConnectionHandler.remove_connection(chatroom_id, conn)
    end
  end

  defp validate_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        case Chat.Token.verify_token(token) do
          {:ok, claims} ->
            {:ok, claims}
          {:error, _reason} ->
            :error
        end
      _ ->
        :error
    end
  end
end
