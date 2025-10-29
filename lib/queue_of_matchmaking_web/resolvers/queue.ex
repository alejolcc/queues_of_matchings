defmodule QueueOfMatchmakingWeb.Resolvers.Queue do
  @moduledoc """
  Resolver functions for the :queue topic.
  """

  alias QueueOfMatchmaking.QueueManager

  @doc """
  Resolver for the `addRequest` mutation.
  """
  def add_request(_parent, %{user_id: "", rank: _rank}, _resolution) do
    {:ok,
     %{
       ok: false,
       error:
         "Invalid input: user_id must be a non-empty string"
     }}
  end

  def add_request(_parent, %{user_id: user_id, rank: rank}, _resolution)
      when is_binary(user_id) and is_integer(rank) and rank >= 0 do
        dbg()
    case QueueManager.add_request(user_id, rank) do
      {:ok, :enqueued} ->
        # Successfully added to the queue
        {:ok, %{ok: true, error: nil}}

      {:ok, :matched} ->
        # Successfully matched immediately
        {:ok, %{ok: true, error: nil}}

      {:error, :already_enqued} ->
        {:ok, %{ok: false, error: "user already on queue"}}
    end
  end
end
