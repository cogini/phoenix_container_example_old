import Config

config :phoenix_container_example, :logger_formatter_config, {:logger_formatter_json,
 %{
   template: [
     :msg,
     :time,
     :level,
     :file,
     :line,
     # :mfa,
     :pid,
     :request_id,
     :trace_id,
     :span_id
   ]
 }}

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix assets.deploy` task,
# which you should run after static files are built and
# before starting your production server.
config :phoenix_container_example, PhoenixContainerExampleWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger,
  level: :info,
  # metadata: :all,
  utc_log: true

# config :logger, :console,
#   format: "$metadata[$level] $message\n",
#   # metadata: [:file, :line, :request_id, :trace_id, :span_id]
#   metadata: :all

config :logger, :default_formatter,
  format: "$metadata[$level] $message\n",
  metadata: [:file, :line, :request_id, :trace_id, :span_id]

# config :logger,
#   handle_otp_reports: true,
#   handle_sasl_reports: true

# config :logger, :default_handler, false

# https://opentelemetry.io/docs/reference/specification/resource/semantic_conventions/
# config :opentelemetry, :resource,
#   [
#     # In production service.name is set based on OS env vars from Erlang release
#     {"service.name", to_string(Mix.Project.config[:app])},
#     # {"service.namespace", "MyNamespace"},
#     {"service.version", Mix.Project.config[:version]},
#   ]

# https://hexdocs.pm/opentelemetry_exporter/1.0.0/readme.html
# Maybe OTEL_EXPORTER_OTLP_ENDPOINT=http://opentelemetry-collector:55680
# config :opentelemetry, :processors,
#   otel_batch_processor: %{
#     exporter: {
#       :opentelemetry_exporter,
#       %{
#         protocol: :grpc,
#         endpoints: [
#           # gRPC
#           ~c"http://localhost:4317"
#           # HTTP
#           # 'http://localhost:4318'
#           # 'http://localhost:55681'
#           # {:http, 'localhost', 4318, []}
#         ]
#         # headers: [{"x-honeycomb-dataset", "experiments"}]
#       }
#     }
#   }

# Configure Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: IotServer.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
