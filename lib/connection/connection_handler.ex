defmodule Chat.ConnectionHandler do
  use GenServer

  # %{ chatroom_id => MapSet<%{conn, user_id}> }
  @initial_state %{}

  # Server
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, @initial_state, name: __MODULE__)
  end

  def add_connection(chatroom_id, conn, user_id, pid) do
    GenServer.call(__MODULE__, {:add_conn, chatroom_id, conn, user_id, pid})
  end

  def remove_connection(chatroom_id, conn) do
    GenServer.call(__MODULE__, {:remove_conn, chatroom_id, conn})
  end

  def broadcast(chatroom_id, message, user_name) do
    GenServer.cast(__MODULE__, {:broadcast, chatroom_id, message, user_name})
  end

  # Callbacks
  @impl true
  def init(_), do: {:ok, @initial_state}

  @impl true
  def handle_call({:add_conn, chatroom_id, conn, user_id, pid}, _from, state) do
    connections = Map.get(state, chatroom_id, MapSet.new())
    filtered_connections =
      Enum.reject(connections, fn %{user_id: uid} -> uid == user_id end)
      |> MapSet.new()
    new_connections = MapSet.put(filtered_connections, %{conn: conn, user_id: user_id, pid: pid})
    IO.inspect(Enum.count(new_connections))
    {:reply, :ok, Map.put(state, chatroom_id, new_connections)}
  end

  @impl true
  def handle_call({:remove_conn, chatroom_id, conn}, _from, state) do
    connections = Map.get(state, chatroom_id, MapSet.new())
    new_connections = 
      Enum.reject(connections, fn %{conn: c} -> c == conn end) 
      |> MapSet.new()
    {:reply, :ok, Map.put(state, chatroom_id, new_connections)}
  end

  @impl true
  def handle_cast({:broadcast, chatroom_id, message, user_name}, state) do
    connections = Map.get(state, "#{chatroom_id}", MapSet.new())

    Enum.each(connections, fn %{conn: conn, pid: pid} -> 
      send(pid, {:send_sse_message, conn, message, user_name})
    end)

    {:noreply, state}
  end
end
