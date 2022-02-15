import Config

# Configure your database
config :phoenix_container_example, PhoenixContainerExample.Repo,
  username: System.get_env("DATABASE_USER") || "postgres",
  password: System.get_env("DATABASE_PASS") || "postgres",
  hostname: System.get_env("DATABASE_HOST") || "localhost",
  database: System.get_env("DATABASE_DB") || "app_dev",
  show_sensitive_data_on_connection_error: true,
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

# For development, we disable any cache and enable
# debugging and code reloading.
#
# The watchers configuration can be used to run external
# watchers to your application. For example, we use it
# with esbuild to bundle .js and .css sources.
config :phoenix_container_example, PhoenixContainerExampleWeb.Endpoint,
  # Binding to loopback ipv4 address prevents access from other machines.
  # Change to `ip: {0, 0, 0, 0}` to allow access from other machines.
  # http: [ip: {127, 0, 0, 1}, port: 4000],
  http: [port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "wSKhk5QDe+kITD/b6Zn16kaOZpyoEvPWLV50DF12lc3RbVwvvxkF/61hl0sEyHbO",
  watchers: [
    # Start the esbuild watcher by calling Esbuild.install_and_run(:default, args)
    esbuild: {Esbuild, :install_and_run, [:default, ~w(--sourcemap=inline --watch)]}
  ]

# ## SSL Support
#
# In order to use HTTPS in development, a self-signed
# certificate can be generated by running the following
# Mix task:
#
#     mix phx.gen.cert
#
# Note that this task requires Erlang/OTP 20 or later.
# Run `mix help phx.gen.cert` for more information.
#
# The `http:` config above can be replaced with:
#
#     https: [
#       port: 4001,
#       cipher_suite: :strong,
#       keyfile: "priv/cert/selfsigned_key.pem",
#       certfile: "priv/cert/selfsigned.pem"
#     ],
#
# If desired, both `http:` and `https:` keys can be
# configured to run both http and https servers on
# different ports.

# Watch static and templates for browser reloading.
config :phoenix_container_example, PhoenixContainerExampleWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/.*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/phoenix_container_example_web/(live|views)/.*(ex)$",
      ~r"lib/phoenix_container_example_web/templates/.*(eex)$"
    ]
  ]

# Do not include metadata nor timestamps in development logs
config :logger, :console, format: "[$level] $message\n"

# Set a higher stacktrace during development. Avoid configuring such
# in production as building large stacktraces may be expensive.
config :phoenix, :stacktrace_depth, 20

# Initialize plugs at runtime for faster development compilation
config :phoenix, :plug_init_mode, :runtime

# https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/
config :opentelemetry, :resource, [
  # In production service.name is set based on OS env vars from Erlang release
  {"service.name", to_string(Mix.Project.config()[:app])},
  # {"service.namespace", "MyNamespace"},
  {"service.version", Mix.Project.config()[:version]}
]

# [
#   service: %{
#     name: to_string(Mix.Project.config[:app]),
#     namespace: "MyNamespace",
#     version: Mix.Project.config[:version],
#   }
# ]

# config :opentelemetry, :processors,
#   otel_batch_processor: %{
#     exporter: {:otel_exporter_stdout, []}
#   }

# https://hexdocs.pm/opentelemetry_exporter/1.0.0/readme.html
# Maybe OTEL_EXPORTER_OTLP_ENDPOINT=http://opentelemetry-collector:55680
config :opentelemetry, :processors,
  otel_batch_processor: %{
    exporter: {
      :opentelemetry_exporter,
      %{
        protocol: :grpc,
        endpoints: [
          # gRPC
          'http://localhost:4317'
          # HTTP
          # 'http://localhost:4318'
          # 'http://localhost:55681'
          # {:http, 'localhost', 4318, []}
        ]
        # headers: [{"x-honeycomb-dataset", "experiments"}]
      }
    }
  }
