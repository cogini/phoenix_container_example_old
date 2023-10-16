defmodule PhoenixContainerExample.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @app :phoenix_container_example

  @impl true
  def start(_type, _args) do
    logger_formatter_config = Application.get_env(@app, :logger_formatter_config)

    if logger_formatter_config do
      :logger.update_handler_config(:default, :formatter, logger_formatter_config)
    end

    OpentelemetryLoggerMetadata.setup()
    OpentelemetryPhoenix.setup()

    children = [
      # Start the Ecto repository
      PhoenixContainerExample.Repo,
      # Start the Telemetry supervisor
      PhoenixContainerExampleWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: PhoenixContainerExample.PubSub},
      # Start the Endpoint (http/https)
      PhoenixContainerExampleWeb.Endpoint
      # Start a worker by calling: PhoenixContainerExample.Worker.start_link(arg)
      # {PhoenixContainerExample.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoenixContainerExample.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhoenixContainerExampleWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
