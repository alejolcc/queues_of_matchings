defmodule QueueOfMatchmakingWeb.UserSocket do
  use Phoenix.Socket

  use Absinthe.Phoenix.Socket,
    schema: QueueOfMatchmakingWeb.Schema

  def id(_socket), do: nil
end
