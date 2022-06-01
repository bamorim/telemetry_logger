defmodule TestTelemetryLogger do
  @moduledoc false

  @behaviour TelemetryLogger
  @default_events [[:telemetry_logger, :test, :event]]

  @impl TelemetryLogger
  def init(opts) do
    {:ok, Keyword.get(opts, :events, @default_events), %{opts: opts}}
  end

  @impl TelemetryLogger
  def handle_event(event, measurements, metadata, config) do
    if Keyword.get(config.opts, :skip, false) do
      :skip
    else
      {
        :log,
        :debug,
        "Handled Event",
        %{measurements: measurements, metadata: metadata, event: event, config: config}
      }
    end
  end
end
