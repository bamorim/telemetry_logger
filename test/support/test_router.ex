defmodule TestRouter do
  use Phoenix.Router

  import Plug.Conn

  scope "/" do
    Phoenix.Router.get("/resource/:id", TestController, :action)
  end
end
