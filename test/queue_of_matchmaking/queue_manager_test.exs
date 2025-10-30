defmodule QueueOfMatchmaking.Queues.QueueManagerTest do
  use QueueOfMatchmakingWeb.ConnCase
  alias QueueOfMatchmaking.Queues.QueueManager
  alias QueueOfMatchmakingWeb.UserSocket

  use Absinthe.Phoenix.SubscriptionTest, schema: QueueOfMatchmakingWeb.Schema

  require Phoenix.ChannelTest

  @shard_id "shard_test"

  setup do
    start_supervised!({QueueManager, shard_id: "test"})
    :ok
  end

  defp subscribe(socket, query) do
    ref = push_doc(socket, query)
    Phoenix.ChannelTest.assert_reply ref, :ok, %{subscriptionId: subscription_id}

    subscription_id
  end

  test "enqueues a user when no match is available" do
    assert QueueManager.add_request("user1", 100, @shard_id) == {:ok, :enqueued}
  end

  test "returns error if user is already enqueued" do
    assert QueueManager.add_request("user1", 100, @shard_id) == {:ok, :enqueued}
    # Add the same user again
    assert QueueManager.add_request("user1", 100, @shard_id) == {:error, :already_enqued}
  end

  test "matches two users at the exact same rank" do
    # assert {:ok, socket} = Phoenix.ChannelTest.connect(UserSocket, %{})
    # assert {:ok, socket} = Absinthe.Phoenix.SubscriptionTest.join_absinthe(socket)

    # subscription_query = """
    #   subscription {
    #     matchFound(userId: "Player123") {
    #       users {
    #         userId
    #         userRank
    #       }
    #     }
    # }
    # """

    # subscription_id = subscribe(socket, subscription_query)

    # Add first user
    assert QueueManager.add_request("user1", 100, @shard_id) == {:ok, :enqueued}

    # Check that is enqueued
    assert QueueManager.add_request("user1", 100, @shard_id) == {:error, :already_enqued}

    # Add second user
    assert QueueManager.add_request("user2", 100, @shard_id) == {:ok, :matched}

    # Now both users should be matched and removed from the queue
    assert QueueManager.add_request("user1", 100, @shard_id) == {:ok, :enqueued}


    # Check for the pubsub message
    # expected_payload = %{
    #   users: [
    #     %{user_id: "user2", user_rank: 100},
    #     %{user_id: "user1", user_rank: 100}
    #   ]
    # }

    # Not sure why this is not working
    # Phoenix.ChannelTest.assert_push("match_found:user1", push, 500)
  end

  test "matches users at the near rank" do
    # Add lower rank user
    assert QueueManager.add_request("user_low", 95, @shard_id) == {:ok, :enqueued}

    # Check that is enqueued
    assert QueueManager.add_request("user_low", 100, @shard_id) == {:error, :already_enqued}

    # Add middle rank user
    assert QueueManager.add_request("user_mid", 100, @shard_id) == {:ok, :matched}

    # Now both users should be matched and removed from the queue
    assert QueueManager.add_request("user_low", 100, @shard_id) == {:ok, :enqueued}

  end
end
