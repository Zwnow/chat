defmodule Chat.RouterTest do
  use Chat.DataCase, async: true
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
    assert String.contains?(conn.resp_body, "email")
  end

  test "parallel registration" do
    num_requests = 100

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
  end

  test "successful login" do
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

    conn =
      conn(:post, "/login", %{
        "email" => "test@example.com",
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
        "user_name" => "testuser",
        "email" => "test@example.com",
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

  defp generate_valid_user(index) do
    %{"user_name" => "user#{index}", "password" => "password!1", "email" => "mail#{index}@test.com"}
  end
end

