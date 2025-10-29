defmodule QueueOfMatchmakingWeb.Schema.Types do
  @moduledoc """
  Defines the custom object types for the GraphQL schema.
  """
  use Absinthe.Schema.Notation

  @desc "The response from an addRequest mutation"
  object :request_response do
    field :ok, non_null(:boolean), description: "True if the request was accepted"
    field :error, :string, description: "An error message, if one occurred"
  end

  @desc "A user who is part of a match"
  object :user_match do
    field :user_id, non_null(:string)
    field :user_rank, non_null(:integer)
  end

  @desc "The payload for a matchFound subscription"
  object :match_payload do
    field :users, non_null(list_of(non_null(:user_match)))
  end
end
