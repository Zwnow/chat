defmodule Chat.Router do
  use Plug.Router

  plug Plug.Logger
  plug Plug.Parsers, parsers: [:json], json_decoder: JasonV
  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Hello, world!")
  end


  post "/register" do
    send_resp(conn, 200, "")
  end

  post "/login" do
    send_resp(conn, 200, "")
  end

  match _ do
    send_resp(conn, 404, "Not found!")
  end
end
