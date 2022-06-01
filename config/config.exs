import Config

if config_env() == :test do
  config :logger,
    backends: [:console, TestLoggerBackend]
end
