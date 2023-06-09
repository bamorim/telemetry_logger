defmodule TelemetryLoggers.LiveViewLogger do
  @moduledoc """
  Logs one log per request on a LiveView call.

  It includes the following metadata:
  - `callback` - Which kind of live view event is listening on, eg: `:mount`, `:handle_params`, etc...
  - `kind` - The source of the event, eg: `live_view` or `live_component`
  - `duration`: The duration in microseconds

  To set this up properly, you want to disable Phoenix built-in logger by adding
  to your config:

      config :phoenix, :logger, false

  Then you need to attach this during application boot with

      TelemetryLogger.attach_loggers([{LiveViewLogger, router: MyAppWeb.Router}])

  By default it will log on `:info` level, you can change that by passing
  `level: level` when attaching, for example:

      TelemetryLogger.attach_loggers([{LiveViewLogger, level: :debug}])

  ## Options

  This logger accepts the following options:

  - `router` - The Phoenix router of your application so this can extract route
    information. If not provided, route information will never be included.
  """

  @behaviour TelemetryLogger

  import TelemetryLoggers.Validators

  @event_names [
    {:live_view, :mount},
    {:live_view, :handle_params},
    {:live_view, :handle_event},
    {:live_component, :handle_event}
  ]

  @doc false
  @impl TelemetryLogger
  def init(opts) do
    level = Keyword.get(opts, :level, :info)
    router = Keyword.get(opts, :router)

    with :ok <- validate_log_level(level) do
      events_names =
        @event_names
        |> Enum.flat_map(fn {kind, callback} ->
          Enum.map([:stop], fn event ->
            [:phoenix, kind, callback, event]
          end)
        end)

      {:ok, events_names, %{level: level, router: router}}
    end
  end

  @doc false
  @impl TelemetryLogger
  def handle_event(
        [_, source, callback, action],
        %{duration: duration} = _measurements,
        metadata,
        %{level: level} = _config
      ) do
    metadata =
      metadata
      |> Map.merge(%{source: source, callback: callback, action: action})
      |> Map.merge(%{duration: duration})
      |> Map.merge(%{event: Map.get(metadata, :event, "")})
      |> Map.merge(%{uri: Map.get(metadata, :uri, "")})
      |> Map.merge(socket_metadata(metadata))

    {:log, level, "#{source} -> #{callback}", metadata}
  end

  @doc false
  @spec socket_metadata(map()) :: map()
  defp socket_metadata(%{socket: socket}) do
    %{
      id: socket.id,
      view: socket.view,
      endpoint: socket.endpoint,
      router: socket.router
    }
  end

  defp socket_metadata(_), do: %{}
end
