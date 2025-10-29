defmodule QueueOfMatchmaking.QueueManager do
  @moduledoc """
  GenServer to manages the state of the matchmaking queue.
  """
  use GenServer
  alias QueueOfMatchmaking.Tree

  # ------------------------------------------------------------------
  # Client API
  # ------------------------------------------------------------------

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Adds a matchmaking request to the queue.
  """
  def add_request(user_id, rank) do
    GenServer.call(__MODULE__, {:add_request, user_id, rank}, 30_000)
  end

  # ------------------------------------------------------------------
  # GenServer Callbacks
  # ------------------------------------------------------------------

  @impl true
  def init(_opts) do
    initial_state = %{
      users_in_queue: MapSet.new(),
      player_queue_by_rank: Tree.empty()
    }

    {:ok, initial_state}
  end

  @impl true
  def handle_call({:add_request, user_id, rank}, _from, state) do
    if MapSet.member?(state.users_in_queue, user_id) do
      # 1. Validation: User is already in the queue.
      {:reply, {:error, :already_enqued}, state}
    else
      # 2. Try to find a match
      case find_match(state.player_queue_by_rank, rank) do
        # 3a. No Match Found: Add the new user to the queue.
        nil ->
          new_state = enqueue_player(state, user_id, rank)
          {:reply, {:ok, :enqueued}, new_state}

        # 3b. Match Found!
        {:ok, {opponent_id, opponent_rank}, tree_without_opponent} ->
          # The opponent was already removed from the tree.
          # We just need to remove them from the user set.
          # The new user (user_id) is *never* added to the state.
          new_users_set = MapSet.delete(state.users_in_queue, opponent_id)

          new_state = %{
            users_in_queue: new_users_set,
            player_queue_by_rank: tree_without_opponent
          }

          # Publish the match to both users
          publish_match(user_id, rank, opponent_id, opponent_rank)

          {:reply, {:ok, :matched}, new_state}
      end
    end
  end

  # ------------------------------------------------------------------
  # Private Helper Functions
  # ------------------------------------------------------------------

  defp enqueue_player(state, user_id, rank) do
    # Add to the user set
    new_users_set = MapSet.put(state.users_in_queue, user_id)

    # Add to the rank tree
    # Get the queue for that rank, or create a new one if it doesn't exist
    rank_queue =
      case Tree.lookup(rank, state.player_queue_by_rank) do
        :none -> :queue.new()
        {:value, queue} -> queue
      end

    updated_rank_queue = :queue.in(user_id, rank_queue)
    new_player_tree = Tree.insert(rank, updated_rank_queue, state.player_queue_by_rank)

    %{
      users_in_queue: new_users_set,
      player_queue_by_rank: new_player_tree
    }
  end

  # Tries to find the closest match.
  # If found, returns `{:ok, {opponent_id, opponent_rank}, updated_tree}`.
  # If not found, returns `nil`.
  defp find_match(tree, rank) do
    # 1. Check for a player at the exact same rank
    case Tree.lookup(rank, tree) do
      :none ->
        # No one at this rank, check neighbors
        find_closest_neighbor(tree, rank)

      {:value, rank_queue} ->
        # Found people at this rank. Try to pop one.
        case pop_from_queue_in_tree(rank, rank_queue, tree) do
          # Queue was empty, check neighbors
          nil -> find_closest_neighbor(tree, rank)
          # Success!
          match -> match
        end
    end
  end

  defp find_closest_neighbor(tree, rank) do
    prev_match = Tree.prev(rank, tree)
    next_match = Tree.next(rank, tree)

    case {prev_match, next_match} do
      # No neighbors in either direction
      {:none, :none} ->
        nil

      # Only a "previous" (lower rank) neighbor
      {{prev_rank, prev_queue}, :none} ->
        pop_from_queue_in_tree(prev_rank, prev_queue, tree)

      # Only a "next" (higher rank) neighbor
      {:none, {next_rank, next_queue}} ->
        pop_from_queue_in_tree(next_rank, next_queue, tree)

      # Both neighbors exist. Find the closer one.
      {{prev_rank, prev_queue}, {next_rank, next_queue}} ->
        delta_prev = rank - prev_rank
        delta_next = next_rank - rank

        if delta_prev <= delta_next do
          # Previous is closer or equidistant. Match with them.
          pop_from_queue_in_tree(prev_rank, prev_queue, tree)
        else
          # Next is closer. Match with them.
          pop_from_queue_in_tree(next_rank, next_queue, tree)
        end
    end
  end

  # Pops one user from a rank's queue and returns the match tuple.
  # It updates the tree, removing the rank key entirely if the queue becomes empty.
  defp pop_from_queue_in_tree(match_rank, match_queue, tree) do
    case :queue.out(match_queue) do
      {:empty, _} ->
        # This queue was empty, so no match here.
        nil

      {{:value, opponent_id}, remaining_queue} ->
        # We found an opponent!
        # Now, update the tree:
        # If the queue is now empty, *delete* the rank from the tree.
        # Otherwise, *update* the rank with the smaller queue.
        new_tree =
          if :queue.is_empty(remaining_queue) do
            Tree.delete(match_rank, tree)
          else
            Tree.insert(match_rank, remaining_queue, tree)
          end

        {:ok, {opponent_id, match_rank}, new_tree}
    end
  end

  # Publishes the match payload to Absinthe subscriptions for *both* users.
  defp publish_match(user_id1, rank1, user_id2, rank2) do
    IO.inspect("Match found")
    IO.inspect({user_id1, rank1})
    IO.inspect({user_id2, rank2})
  end
end
