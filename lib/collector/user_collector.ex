defmodule Chat.UserCollector do
  use GenServer

  @initial_state %{count: 0, elements: [], flush_timer: nil}
  @batch_size 100
  @flush_interval 500

  # Server
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, @initial_state, name: __MODULE__)
  end

  def add_user(user) do
    GenServer.cast(__MODULE__, {:add_user, user})
  end

  defp flush_users(@initial_state), do: :ok
  defp flush_users(state) do
    #Chat.Repo.transaction(fn -> 
    Enum.each(state.elements, &Chat.Repo.insert!(&1))
    #end)
  end

  defp schedule_flush(state) do
    state.flush_timer && Process.cancel_timer(state.flush_timer)
    new_timer = Process.send_after(self(), :flush, @flush_interval)
    %{state | flush_timer: new_timer}
  end

  # Callbacks
  @impl true
  def init(_) do
    {:ok, @initial_state}
  end

  @impl true
  def handle_cast({:add_user, user}, state) do
    new_state = %{count: state.count + 1, elements: [ user | state.elements ], flush_timer: state.flush_timer}
    if new_state.count >= @batch_size do
      flush_users(new_state)
      {:noreply, schedule_flush(%{@initial_state | flush_timer: state.flush_timer})}
    else
      {:noreply, schedule_flush(new_state)}
    end
  end

  @impl true
  def handle_info(:flush, state) do
    flush_users(state)
    {:noreply, schedule_flush(%{@initial_state | flush_timer: state.flush_timer})}
  end
end
