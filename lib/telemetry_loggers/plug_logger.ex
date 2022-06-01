defmodule TelemetryLoggers.PlugLogger do
  @moduledoc """
  Logs one log per request on a Phoenix router.

  It includes the following metadata:
  - `duration_us`: The duration in microseconds
  - `status`: The response HTTP status
  - `method`: The request HTTP method
  - `path`: The request path (can be hidden by passing `include_path: false`)

  If Phoenix is present and the router is passed
  - `route`: The matched Phoenix Route
  - `route_plug`: The plug of the matched route, probably your controller
  - `route_plug_opts`: The plug options of the matched route, probably your
    action name

  To set this up properly, you want to disable Phoenix built-in logger by adding
  to your config:

      config :phoenix, :logger, false

  Then you need to attach this during application boot with

      TelemetryLogger.attach_loggers([PlugLogger])

  For Phoenix applications, you probably want to specify the PlugLogger

      TelemetryLogger.attach_loggers([{PlugLogger, router: MyAppWeb.Router}])

  By default it will log on `:info` level, you can change that by passing
  `level: level` when attaching, for example:any()

      TelemetryLogger.attach_loggers([{PlugLogger, level: :debug}])

  ## Options

  This logger accepts the following options

  - `:level` - The log level to use. By default it uses `:info`
  - `:router` - The Phoenix router of your application so this can extract route
    information. If not provided, route information will never be included.
  - `:include_path` - Some sensitive applications might want to make sure path
    params are not leaked in the logs as they might contain sensistive
    information. For these cases, `include_path: false` will disable that and
    will only log route information (e.g. `/user/:id` instead of `/user/12345`).
    This is true by default.
  - `:prefix` - The prefix of the `Plug.Telemetry` events, by default it is
    `[:phoenix, :endpoint]`
  """

  @behaviour TelemetryLogger

  import TelemetryLoggers.Validators

  @doc false
  @impl TelemetryLogger
  def init(opts \\ []) do
    level = Keyword.get(opts, :level, :info)
    router = Keyword.get(opts, :router)
    include_path = Keyword.get(opts, :include_path, true)
    prefix = Keyword.get(opts, :prefix, [:phoenix, :endpoint])

    with :ok <- validate_log_level(level) do
      {:ok, [prefix ++ [:stop]], %{level: level, router: router, include_path: include_path}}
    end
  end

  @doc false
  @impl TelemetryLogger
  def handle_event(_, %{duration: duration}, metadata, %{level: level} = config) do
    %{conn: conn} = metadata

    metadata =
      metadata
      |> Map.merge(%{
        duration_us: convert_duration(duration),
        status: conn.status,
        method: conn.method
      })
      |> Map.merge(path_metadata(conn, config))
      |> Map.merge(route_metadata(conn, config))

    {:log, level, message(metadata), metadata}
  end

  defp convert_duration(duration) do
    System.convert_time_unit(duration, :native, :microsecond)
  end

  defp message(%{method: method, status: status} = metadata) do
    route = Map.get(metadata, :route, "nil")
    path_or_route = Map.get(metadata, :path, route)
    "#{method} #{path_or_route} -> #{status}"
  end

  defp route_metadata(_, %{router: nil}), do: %{}

  defp route_metadata(conn, %{router: router}) do
    case Phoenix.Router.route_info(router, conn.method, conn.request_path, "") do
      :error ->
        %{}

      %{route: route, plug: plug, plug_opts: plug_opts} ->
        %{
          route: route,
          route_plug_opts: plug_opts,
          route_plug: plug
        }
    end
  end

  defp path_metadata(_conn, %{include_path: false}), do: %{}

  defp path_metadata(conn, %{include_path: true}) do
    %{path: conn.request_path}
  end
end
