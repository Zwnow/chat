defmodule Chat.Router do
  use Plug.Router
  import Ecto.Query

  plug Plug.Logger
  plug Plug.Parsers, parsers: [:json], json_decoder: Jason
  plug CORSPlug
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

  get "/validate-token" do
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
          {:ok, _} -> 
            room = Chat.Chatroom |> Chat.Repo.one()
            send_resp(conn, 201, "#{room.id}")
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
        send_resp(conn, 200, json_response)
      :error -> send_resp(conn, 400, "Failed to authenticate")
    end
  end

  get "/chatroom/:chatroom_id/:token" do
    case validate_token(token) do
      {:ok, _claims} -> 
        conn =
          conn
          |> Plug.Conn.put_resp_content_type("text/event-stream")
          |> Plug.Conn.send_chunked(200)

        {:ok, _pid} = Registry.register(Chat.Registry, chatroom_id, self())

        stream_messages(conn, chatroom_id)
      :error -> 
        send_resp(conn, 400, "Failed to authenticate")
    end
  end

  post "/message/:chatroom_id" do
    case validate_token(conn) do
      {:ok, claims} -> 
        id = claims["id"]
        user = Chat.User |> Ecto.Query.where(id: ^id) |> Chat.Repo.one()

        if user do
          updated_conn = %Plug.Conn{conn | body_params: Map.merge(conn.body_params, %{"user_id" => user.id, "user_name" => user.user_name, "chatroom" => chatroom_id})}
          case Chat.Message.store_message(updated_conn.body_params) do
            :ok -> 
              send_resp(updated_conn, 200, "sent")
            {:error, _} -> 
              send_resp(updated_conn, 400, "failed to send")
          end
        else
          send_resp(conn, 404, "User not found")
        end
      :error -> send_resp(conn, 400, "Failed to authenticate")
    end
  end

  match _ do
    send_resp(conn, 404, "Not found!")
  end

  defp validate_token(token) when is_binary(token) do
    case Chat.Token.verify_token(token) do
      {:ok, claims} ->
        {:ok, claims}
      {:error, _reason} ->
        :error
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

  defp stream_messages(conn, chatroom_id) do
    receive do
      {:message, msg} ->
        case Plug.Conn.chunk(conn, "data: #{msg}") do
          {:ok, _} -> stream_messages(conn, chatroom_id)
          {:error, _} -> 
            Process.exit(self(), :shutdown)
        end
    after
      15_000 ->
        case Plug.Conn.chunk(conn, ":\n\n") do
          {:ok, _} -> stream_messages(conn, chatroom_id)
          {:error, _} -> 
            Process.exit(self(), :shutdown)
        end
    end
  end
end
