defmodule QueueOfMatchmakingWeb.Schema do
  use Absinthe.Schema

  import_types QueueOfMatchmakingWeb.Schema.Types

  query do
    @desc "Get the version of the API"
    field :version, :string do
      resolve fn _, _ ->
        {:ok, "1.0.0"}
      end
    end
  end
end
