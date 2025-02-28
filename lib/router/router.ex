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
      {:ok, claims} -> 
        %{"id" => id} = claims
        if chatroom_member?(chatroom_id, id) do
          conn =
            conn
            |> Plug.Conn.put_resp_content_type("text/event-stream")
            |> Plug.Conn.send_chunked(200)

          {:ok, _pid} = Registry.register(Chat.Registry, chatroom_id, self())

          stream_messages(conn, chatroom_id)
        else
          send_resp(conn, 400, "Not a chatroom member")
        end
      :error -> 
        send_resp(conn, 400, "Failed to authenticate")
    end
  end

  post "/chatinvite" do
    case validate_token(conn) do
      {:ok, claims} ->
        %{"id" => id} = claims
        updated_conn = %Plug.Conn{conn | body_params: Map.merge(conn.body_params, %{"user_id" => id})}
        case Chat.ChatInvitation.create(updated_conn.body_params) do
          :ok -> send_resp(conn, 201, "Invitation sent")
          {:error, msg} -> send_resp(conn, 400, msg)
        end
      :error -> send_resp(conn, 400, "Failed to authenticate")
    end
  end

  get "/chatinvite" do
    case validate_token(conn) do
      {:ok, claims} ->
        %{"id" => id} = claims
        invites = Chat.ChatInvitation.get(id)
        send_resp(conn, 200, Jason.encode!(%{invites: invites}))
      :error -> send_resp(conn, 400, "Failed to authenticate")
    end
  end

  post "/invitation/accept" do
    case validate_token(conn) do
      {:ok, claims} ->
        %{"id" => id} = claims
        updated_conn = %Plug.Conn{conn | body_params: Map.merge(conn.body_params, %{"user_id" => id})}
        case Chat.ChatInvitation.accept_invitation(updated_conn.body_params) do
          :ok -> send_resp(updated_conn, 200, "Invitation accepted")
          {:error, msg} -> send_resp(updated_conn, 400, msg)
        end
      :error -> send_resp(conn, 400, "Failed to authenticate")
    end
  end

  post "/invitation/decline" do
    case validate_token(conn) do
      {:ok, claims} ->
        %{"id" => id} = claims
        updated_conn = %Plug.Conn{conn | body_params: Map.merge(conn.body_params, %{"user_id" => id})}
        case Chat.ChatInvitation.decline_invitation(updated_conn.body_params) do
          :ok -> send_resp(updated_conn, 200, "Invitation accepted")
          {:error, msg} -> send_resp(updated_conn, 400, msg)
        end
      :error -> send_resp(conn, 400, "Failed to authenticate")
    end
  end

  post "/message/:chatroom_id" do
    case validate_token(conn) do
      {:ok, claims} -> 
        %{"id" => id} = claims
        if chatroom_member?(chatroom_id, id) do
          user = Chat.User 
            |> Ecto.Query.where(id: ^id) 
            |> Chat.Repo.one()

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
        else
            send_resp(conn, 404, "Cant send to this chatroom")
        end
      :error -> send_resp(conn, 400, "Failed to authenticate")
    end
  end

  get "/message/:chatroom_id" do
    case validate_token(conn) do
      {:ok, claims} -> 
        %{"id" => id} = claims
        if chatroom_member?(chatroom_id, id) do
          page = Map.get(conn.params, "page", "1") |> String.to_integer()
          query = from m in Chat.Message,
            join: u in Chat.User, on: m.user_id == u.id,
            where: m.chatroom_id == ^chatroom_id,
            order_by: [desc: m.inserted_at],
            limit: 200,
            offset: ^((page - 1) * 200),
            select: %{
              id: m.id,
              content: m.content,
              user_id: m.user_id,
              user_name: u.user_name,
              inserted_at: m.inserted_at
            }

          messages = Chat.Repo.all(query)
          send_resp(conn, 200, Jason.encode!(%{messages: messages}))
        end
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

  defp chatroom_member?(chatroom_id, id) do
    chatroom_id = String.to_integer(chatroom_id)
    room = Chat.ChatroomMember |> Ecto.Query.where([user_id: ^id, chatroom_id: ^chatroom_id]) |> Chat.Repo.one()
    room != nil
  end

  defp stream_messages(conn, chatroom_id) do
    Process.flag(:trap_exit, true)

    receive do
      {:message, msg} ->
        case Plug.Conn.chunk(conn, "data: #{msg}") do
          {:ok, _} -> stream_messages(conn, chatroom_id)
          {:error, _} -> 
            {:halt, conn}
        end
    after
      15_000 ->
        case Plug.Conn.chunk(conn, ":\n\n") do
          {:ok, _} -> stream_messages(conn, chatroom_id)
          {:error, _} -> 
            {:halt, conn}
        end
    end
  end
end
