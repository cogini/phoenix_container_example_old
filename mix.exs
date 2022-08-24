defmodule PhoenixContainerExample.MixProject do
  use Mix.Project

  @version "0.1.0"
  @app :phoenix_container_example

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      # elixirc_options: [warnings_as_errors: Mix.env() != :dev],
      # compilers: Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      dialyzer: [
        # plt_add_deps: :project,
        # plt_add_apps: [:ssl, :mnesia, :compiler, :xmerl, :inets],
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
        "coveralls.lcov": :test
      ],
      deps: deps(),
      default_release: :prod,
      releases: releases()
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
        version: @version,
        include_executables_for: [:unix]
        # applications: [:runtime_tools :permanent, :opentelemetry_exporter :load, :opentelemetry :temporary, @app :permanent]
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
      # {:opentelemetry_phoenix, "~> 0.2.0"},
      {:coverex, "~> 1.5", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: [:dev, :test], runtime: false},
      {:ecto_sql, "~> 3.6"},
      {:esbuild, "~> 0.3", runtime: Mix.env() == :dev},
      {:excoveralls, "~> 0.14", only: [:dev, :test]},
      {:floki, ">= 0.30.0", only: :test},
      {:gettext, "~> 0.18"},
      {:jason, "~> 1.2"},
      {:junit_formatter, "~> 3.3", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.0", only: [:dev, :test], runtime: false},
      {:opentelemetry, "~> 1.0", override: true},
      {:opentelemetry_api, "~> 1.0", override: true},
      {:opentelemetry_ecto, "~> 1.0.0-rc.5"},
      {:opentelemetry_exporter, "~> 1.0"},
      {:opentelemetry_logger_metadata, "~> 0.1.0"},
      {:opentelemetry_phoenix, "~> 1.0.0-rc.7"},
      {:phoenix, "~> 1.6.6"},
      {:phoenix_ecto, "~> 4.4"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_live_dashboard, "~> 0.6"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.17.5"},
      {:plug_cowboy, "~> 2.5"},
      {:postgrex, ">= 0.0.0"},
      {:sobelow, "~> 0.11.0", only: [:dev, :test], runtime: false},
      {:swoosh, "~> 1.3"},
      {:telemetry, "~> 1.0", override: true},
      {:telemetry_metrics, "~> 0.6"},
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
      # setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      setup: ["deps.get", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.deploy": ["esbuild default --minify", "phx.digest"]
    ]
  end
end
