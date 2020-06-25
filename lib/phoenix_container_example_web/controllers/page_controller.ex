defmodule PhoenixContainerExampleWeb.PageController do
  use PhoenixContainerExampleWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
