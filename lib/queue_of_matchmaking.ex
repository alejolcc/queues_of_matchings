defmodule QueueOfMatchmaking do
  @moduledoc """
  TLDR:
  To scale and avoid matching too long we split the queues per range (the algorithm can be changed simple)

  If we use just a GenServer for the matching we have 2 problems,
  1) The distance between matching can be very big
  2) The GenServer can be a bottleneck

  For that we have multiples genserver to handles ranges of ranks and each user will belong to one queue or another depend on the rank. The counter part of that is that the user in one queue will not see the user of another queue.

  The num_partitions can be configured, if we configure the partitions in 1 we only have 1 queue of rankings
  """
  alias QueueOfMatchmaking.Queues.QueueManager

  @partition_size 1000

  @doc """
  Adds a matchmaking request to the queue.
  This function is the "router".
  """
  def add_request(user_id, rank) do
    # 1. Sharding Logic: Find the correct shard_id
    shard_id = hash_function(rank, num_partitions())
    shard_id = "shard_#{shard_id}"

    QueueManager.add_request(user_id, rank, shard_id)
  end

  # With this function we can handle the matching logic
  # Now implements a simple range-based partitioning
  defp hash_function(rank, partitions) do
    shard_index = div(rank, @partition_size)

    # 2. Get the index of the *last* partition
    last_partition_index = partitions - 1

    # 3. Cap the index at the last partition.
    # This makes 9000+ (bucket 9, 10, 11...) all go into the last one (bucket 9).
    min(shard_index, last_partition_index)
  end

  defp num_partitions do
    Application.get_env(:queue_of_matchmaking, :num_partitions, 10)
  end
end
