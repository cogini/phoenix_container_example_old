defmodule PhoenixContainerExample.MixProject do
  use Mix.Project

  @app :phoenix_container_example
  @version "0.1.0"

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      # elixirc_options: [warnings_as_errors: Mix.env() != :dev],
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      dialyzer: [
        # plt_add_deps: :project,
        # plt_add_apps: [:ssl, :mnesia, :compiler, :xmerl, :inets],
        plt_add_apps: [:mix, :ex_unit]
        # plt_add_apps: [:poison],
        # plt_add_deps: true,
        # flags: ["-Werror_handling", "-Wrace_conditions"],
        # flags: ["-Wunmatched_returns", :error_handling, :race_conditions, :underspecs],
        # ignore_warnings: "dialyzer.ignore-warnings"
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.lcov": :test,
        quality: :test,
        "quality.ci": :test
      ],
      default_release: :prod,
      releases: releases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PhoenixContainerExample.Application, []},
      extra_applications:
        [:logger, :runtime_tools, :gproc, :tls_certificate_check, :ssl, :eex] ++
          extra_applications(Mix.env())
    ]
  end

  def extra_applications(:test), do: [:tools]
  def extra_applications(:dev), do: [:tools]
  def extra_applications(_), do: []

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp releases do
    [
      prod: [
        include_executables_for: [:unix]
        # Don't need to tar if we are just going to copy it
        # steps: [:assemble, :tar]
      ]
    ]
  end

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.2", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.6"},
      {:esbuild, "~> 0.4", runtime: Mix.env() == :dev},
      {:excoveralls, "~> 0.14", only: [:dev, :test], runtime: false},
      {:flatlog, "~> 0.1.2", only: :dev},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:junit_formatter, "~> 3.3", only: [:dev, :test], runtime: false},
      {:logger_formatter_json, github: "reachfh/logger_formatter_json"},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:observer_cli, "~> 1.7"},
      {:opentelemetry, "~> 1.1"},
      {:opentelemetry_api, "~> 1.1"},
      {:opentelemetry_ecto, "~> 1.0"},
      {:opentelemetry_exporter, "~> 1.1"},
      {:opentelemetry_logger_metadata, "~> 0.1.0"},
      {:opentelemetry_phoenix, "~> 1.0"},
      {:phoenix, "~> 1.6.11"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_dashboard, "~> 0.7"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.18"},
      {:plug_cowboy, "~> 2.5"},
      {:postgrex, ">= 0.0.0"},
      {:sobelow, "~> 0.11", only: [:dev, :test], runtime: false},
      {:swoosh, "~> 1.3"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_metrics_prometheus, "~> 1.1"},
      # {:telemetry_metrics_statsd, "~> 0.6.2"},
      {:telemetry_poller, "~> 1.0"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"],
      # "assets.deploy": ["yarn --cwd assets deploy", "phx.digest"],
      quality: [
        "format --check-formatted",
        "credo",
        "dialyzer --halt-exit-status",
        "sobelow --exit"
      ],
      "quality.ci": [
        "format --check-formatted",
        "credo --ignore refactor,duplicated",
        "dialyzer --halt-exit-status",
        "sobelow --exit"
      ]
    ]
  end
end
