defmodule QueueOfMatchmakingWeb.Schema do
  @moduledoc """
  The main Absinthe schema.
  """
  use Absinthe.Schema

  # Import all our custom types
  import_types(QueueOfMatchmakingWeb.Schema.Types)

  # Import the resolvers
  alias QueueOfMatchmakingWeb.Resolvers

  query do
    import_fields(:request_response)
    import_fields(:user_match)
    import_fields(:match_payload)
  end

  # ---
  # Mutation
  # ---

  mutation do
    @desc "Adds a user to the matchmaking queue"
    field :add_request, :request_response do
      arg(:user_id, non_null(:string))
      arg(:rank, non_null(:integer))

      resolve(&Resolvers.Queue.add_request/3)
    end
  end

  # ---
  # Subscription
  # ---
  subscription do
    @desc "Notifies a user when a match is found"
    field :match_found, :match_payload do
      arg(:user_id, non_null(:string))

      # Configure the subscription to use the user_id as a dynamic topic.
      # This ensures a user only gets *their own* match notifications.
      config(fn args, _ ->
        {:ok, topic: "match_found:#{args.user_id}"}
      end)

      # The resolver just passes the payload through.
      # The "publishing" is done in the QueueManager.
      resolve(fn payload, _, _ ->
        {:ok, payload}
      end)
    end
  end
end
