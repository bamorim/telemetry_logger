defmodule MixProject do
  use Mix.Project

  def project do
    [
      app: :telemetry_logger,
      version: "0.1.0",
      elixir: "~> 1.11",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: [
        plt_file: {:no_warn, "priv/plts/dialyzer.plt"},
        plt_add_apps: [:mix, :credo]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      name: "TelemetryLogger",
      source_url: "https://github.com/bamorim/telemetry_logger",
      homepage_url: "https://github.com/bamorim/telemetry_logger",
      docs: [
        # The main page in the docs
        main: "TelemetryLogger",
        extras: ["README.md"]
      ]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:telemetry, "~> 1.0"},
      {:logfmt, "~> 3.3"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.1", only: :dev, runtime: false},
      {:doctor, "~> 0.18.0", only: :dev, runtime: false},
      {:ex_check, "~> 0.14.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.28", only: :dev, runtime: false},
      {:mock, "~> 0.3.7", only: [:dev, :test]},
      {:excoveralls, "~> 0.14", only: :test},
      {:phoenix, "~> 1.5", optional: true}
    ]
  end
end
