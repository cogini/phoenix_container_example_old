import Config

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix assets.deploy` task,
# which you should run after static files are built and
# before starting your production server.
config :phoenix_container_example, PhoenixContainerExampleWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :iot_server, Uinta.Plug, json: true
# Include GraphQL variables in log line
# include_variables: true,
# ignored_paths: [],
# filter_variables: [],
# success_log_sampling_ratio: 1.0,
# include_datadog_fields: false

config :logger, level: :info, utc_log: true

# config :logger, :console,
#   format: "$metadata[$level] $message\n",
#   # metadata: [:file, :line, :request_id, :trace_id, :span_id]
#   metadata: :all

# config :logger, :default_formatter,
#   format: "$metadata[$level] $message\n",
#   metadata: [:file, :line, :pid, :request_id, :trace_id, :span_id]

config :logger, :default_handler,
  formatter: {
    :logger_formatter_json,
    %{
      template: [
        :msg,
        # :time,
        :level,
        :file,
        :line,
        # :mfa,
        :pid,
        :request_id,
        :trace_id,
        :span_id
      ]
    }
  }

# config :logger,
#   handle_otp_reports: true,
#   handle_sasl_reports: true

# config :logger, :default_handler, false

# https://hexdocs.pm/opentelemetry_exporter/readme.html
# Set via environment vars because server name is different in docker compose vs ECS:
#   OTEL_EXPORTER_OTLP_ENDPOINT="http://localhost:4317"
#   OTEL_EXPORTER_OTLP_PROTOCOL="grpc"
#
# config :opentelemetry, :processors,
# otel_batch_processor: %{
#   exporter: {
#     :opentelemetry_exporter,
#     %{
#       protocol: :grpc,
#       endpoints: [
#         # gRPC
#         ~c"http://localhost:4317"
#         # HTTP
#         # 'http://localhost:4318'
#         # 'http://localhost:55681'
#         # {:http, 'localhost', 4318, []}
#       ]
#       # headers: [{"x-honeycomb-dataset", "experiments"}]
#     }
#   }
# }

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: IotServer.Finch

# Disable Swoosh Local Memory Storage
config :swoosh, local: false

# config :tzdata, :data_dir, "/var/lib/tzdata"

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
