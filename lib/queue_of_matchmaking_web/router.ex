defmodule QueueOfMatchmakingWeb.Router do
  use QueueOfMatchmakingWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/api", QueueOfMatchmakingWeb do
    pipe_through :api
  end
end
