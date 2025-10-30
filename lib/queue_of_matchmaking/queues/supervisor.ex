defmodule QueueOfMatchmaking.Queues.Supervisor do
  @moduledoc """
  Supervises the Registry and all Queue.Shard workers.
  """
  use Supervisor

  alias QueueOfMatchmaking.Queues.QueueManager

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(init_arg) do
    partitions = Keyword.get(init_arg, :partitions, num_partitions())

    children =
      [
        {Registry, keys: :unique, name: ShardsRegistry}
      ] ++
        Enum.map(0..(partitions - 1), fn shard_id ->
          Supervisor.child_spec({QueueManager, shard_id: shard_id}, id: :"shard_#{shard_id}")
        end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  defp num_partitions do
    Application.get_env(:queue_of_matchmaking, :num_partitions, 10)
  end
end
