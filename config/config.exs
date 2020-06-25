# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :phoenix_container_example,
  ecto_repos: [PhoenixContainerExample.Repo]

# Configures the endpoint
config :phoenix_container_example, PhoenixContainerExampleWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "RKbLg7NAE0pwJaybW3hMJm1r1IFOPhszYnvg4lBFjfmAVcdDvsTOeAllb8eL6vpc",
  render_errors: [view: PhoenixContainerExampleWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: PhoenixContainerExample.PubSub,
  live_view: [signing_salt: "h8yAjCd8"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
