defmodule Mixite.EventManager do
  use GenStage

  def start_link(args) do
    GenStage.start_link(__MODULE__, args, name: __MODULE__)
  end

  def notify(msg) do
    GenStage.cast(__MODULE__, {:notify, msg})
  end

  @impl GenStage
  def init(_args) do
    {:producer, [], dispatcher: GenStage.BroadcastDispatcher}
  end

  @impl GenStage
  def handle_cast({:notify, msg}, state) do
    {:noreply, [msg], state}
  end

  @impl GenStage
  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end
end
