defmodule QueueOfMatchmakingWeb.Router do
  use QueueOfMatchmakingWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api" do
    pipe_through :api

    forward "/graphiql", Absinthe.Plug.GraphiQL,
      schema: QueueOfMatchmakingWeb.Schema,
      socket: QueueOfMatchmakingWeb.UserSocket,
      interface: :simple

    forward "/", Absinthe.Plug,
      schema: QueueOfMatchmakingWeb.Schema
  end
end
