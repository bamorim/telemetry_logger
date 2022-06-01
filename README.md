# TelemetryLogger

TelemetryLogger implements infrastructure to have metadata-rich logs from
`:telemetry` events. The goal is to also include loggers for existing well-known
libraries such as Phoenix, Ecto, Tesla, Oban, etc.

## Installation

For now this package is only available through git, so to install you can add:

```elixir
def deps do
  [
    {:telemetry_logger, github: "bamorim/telemetry_logger"}
  ]
end
```