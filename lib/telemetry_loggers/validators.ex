defmodule TelemetryLoggers.Validators do
  @moduledoc false
  # This contains helper functions to validate options passed to our loggers.

  @valid_levels [
    :emergency,
    :alert,
    :critical,
    :error,
    :warning,
    :warn,
    :notice,
    :info,
    :debug
  ]

  @doc false
  @spec validate_log_level(atom()) :: :ok | {:error, :invalid_log_level}
  def validate_log_level(level) when level in @valid_levels, do: :ok
  def validate_log_level(_), do: {:error, :invalid_log_level}
end
