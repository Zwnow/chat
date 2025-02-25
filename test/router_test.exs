defmodule Chat.RouterTest do
  use Chat.DataCase, async: false
  use Plug.Test
  alias Chat.Router

  @opts Router.init([])

  test "successful user registration" do
    conn =
      conn(:post, "/register", %{
        "user_name" => "testuser",
        "email" => "test@example.com",
        "password" => "somePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 201
    assert conn.resp_body == "User registered"
  end

  test "registration fails with missing email" do
    conn =
      conn(:post, "/register", %{
        "user_name" => "testuser",
        "password" => "somePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 400
    assert String.contains?(conn.resp_body, "Invalid")
  end

  test "successful login" do
    conn =
      conn(:post, "/register", %{
        "user_name" => "loginuser",
        "email" => "test@exampl22.com",
        "password" => "somePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 201
    assert conn.resp_body == "User registered"

    Process.sleep(1000)

    conn =
      conn(:post, "/login", %{
        "email" => "test@exampl22.com",
        "password" => "somePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    assert String.contains?(conn.resp_body, "token")
  end


  test "wrong password" do
    conn =
      conn(:post, "/register", %{
        "user_name" => "wrongpwd",
        "email" => "test@examplee.com",
        "password" => "somePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 201
    assert conn.resp_body == "User registered"

    conn =
      conn(:post, "/login", %{
        "email" => "test@example.com",
        "password" => "smePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 400
  end


  test "parallel registration" do
    assert Chat.Repo.all(Chat.User) |> Enum.count() == 0

    num_requests = 1

    user_data = 1..num_requests |> Enum.map(&generate_valid_user(&1))

    results = 
      user_data
      |> Task.async_stream(fn user ->
      conn = conn(:post, "/register", user)
        |> put_req_header("content-type", "application/json")
        |> Router.call(@opts)

      assert conn.status == 201
      assert conn.resp_body == "User registered"
    end, max_concurrency: 10)

    Enum.to_list(results)

    assert Chat.Repo.all(Chat.User) |> Enum.count() == num_requests 
  end

  test "validate token" do
    conn =
      conn(:post, "/register", %{
        "user_name" => "loginuser",
        "email" => "test@exampl22.com",
        "password" => "somePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 201
    assert conn.resp_body == "User registered"

    Process.sleep(1000)

    conn =
      conn(:post, "/login", %{
        "email" => "test@exampl22.com",
        "password" => "somePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    assert String.contains?(conn.resp_body, "token")

    body = case Jason.decode(conn.resp_body) do
      {:ok, data} -> data
      {:error, _} -> assert false
    end

    {:ok, token} = Map.fetch(body, "token")

    conn =
      conn(:post, "/validate-token", %{
        "email" => "test@exampl22.com",
        "password" => "somePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> put_req_header("authorization", "Bearer #{token}")
      |> Router.call(@opts)

    assert conn.status == 200
    assert String.contains?(conn.resp_body, "Token valid")
  end

  test "5000 messages" do
    conn =
      conn(:post, "/register", %{
        "user_name" => "login3ser",
        "email" => "test@exampl32.com",
        "password" => "somePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 201
    assert conn.resp_body == "User registered"

    Process.sleep(1000)

    conn =
      conn(:post, "/login", %{
        "email" => "test@exampl32.com",
        "password" => "somePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    assert String.contains?(conn.resp_body, "token")

    body = case Jason.decode(conn.resp_body) do
      {:ok, data} -> data
      {:error, _} -> assert false
    end

    {:ok, token} = Map.fetch(body, "token")

    conn =
      conn(:post, "/chatroom", "{\"name\":\"asdf\"}")
      |> put_req_header("content-type", "application/json")
      |> put_req_header("authorization", "Bearer #{token}")
      |> Router.call(@opts)

    assert conn.status == 201

    id = conn.resp_body
    num_requests = 1..20000

    results = 
      num_requests
      |> Task.async_stream(fn user ->
        conn = conn(:post, "/message/#{id}", "{\"content\":\"Test message\"}")
          |> put_req_header("content-type", "application/json")
          |> put_req_header("authorization", "Bearer #{token}")
          |> Router.call(@opts)
      end, max_concurrency: 10)

    Enum.to_list(results)

    assert Chat.Repo.all(Chat.Message) |> Enum.count() == 20000
  end

  test "invalid token" do
    conn =
      conn(:post, "/register", %{
        "user_name" => "loginuser",
        "email" => "test@exampl22.com",
        "password" => "somePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 201
    assert conn.resp_body == "User registered"

    Process.sleep(1000)

    conn =
      conn(:post, "/login", %{
        "email" => "test@exampl22.com",
        "password" => "somePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> Router.call(@opts)

    assert conn.status == 200
    assert String.contains?(conn.resp_body, "token")

    body = case Jason.decode(conn.resp_body) do
      {:ok, data} -> data
      {:error, _} -> assert false
    end

    {:ok, token} = Map.fetch(body, "token")

    conn =
      conn(:post, "/validate-token", %{
        "email" => "test@exampl22.com",
        "password" => "somePass123",
      })
      |> put_req_header("content-type", "application/json")
      |> put_req_header("authorization", "Bearer 1232141532")
      |> Router.call(@opts)

    assert conn.status == 404
    assert String.contains?(conn.resp_body, "Token valid")
  end

  defp generate_valid_user(index) do
    %{"user_name" => "user#{index}", "password" => "password!1", "email" => "mail#{index}@test.com"}
  end
end

