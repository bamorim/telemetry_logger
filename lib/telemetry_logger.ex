defmodule TelemetryLogger do
  @moduledoc """
  Defines a behaviour for loggers based on telemetry events.

  It also contains a helper function `attach_loggers/1` to attach to the
  `:telemetry` runtime and start logging results.
  """

  @callback init(keyword()) ::
              {:ok, [:telemetry.event_name()], :telemetry.handler_config()}
              | {:error, term()}

  @callback handle_event(
              :telemetry.event_name(),
              :telemetry.event_measurements(),
              :telemetry.event_metadata(),
              :telemetry.handler_config()
            ) ::
              {:log, Logger.level(), Logger.message(), Logger.metadata() | %{atom() => term()}}
              | :skip

  @doc """
  Attaches to `:telemetry` and forward events to telemetry loggers and then
  calls Logger properly.

  The values on the logger list are passed to `init/1` callback.

  Example:

      TelemetryLogger.attach_loggers(
        MyLogger,
        {AnotherLogger, something: 1234}
      )

  Will result in calls `MyLogger.init([])` and `AnotherLogger.init(something:
  1234)` which will then be passed as the last argument to
  `MyLogger.handle_event/4` and `AnotherLogger.handle_event/4` respectively.
  """
  @spec attach_loggers([module() | {module(), keyword()}]) ::
          :ok | {:error, {:already_exists, [{atom(), keyword()}]}}
  def attach_loggers(loggers) do
    results =
      for {logger, opts} <- normalize_loggers(loggers) do
        {:ok, events, config} = logger.init(opts)

        result =
          :telemetry.attach_many(
            {__MODULE__, logger, opts},
            events,
            &__MODULE__.handle_event/4,
            %{logger: logger, logger_config: config}
          )

        {result, logger, opts}
      end

    existing = for {{:error, :already_exists}, logger, opts} <- results, do: {logger, opts}

    case existing do
      [] -> :ok
      _ -> {:error, {:already_exists, existing}}
    end
  end

  defp normalize_loggers(loggers) do
    Enum.map(loggers, fn
      {logger, opts} when is_atom(logger) ->
        {logger, opts}

      logger when is_atom(logger) ->
        {logger, []}

      config ->
        raise "Invalid Logger config #{inspect(config)}.\nExpecting either a module or a `{mod, opts}` tuple."
    end)
  end

  @doc false
  def handle_event(
        event_name,
        measurements,
        metadata,
        %{
          logger: logger,
          logger_config: logger_config
        },
        log_fn \\ &Logger.bare_log/3
      ) do
    :ok

    case logger.handle_event(event_name, measurements, metadata, logger_config) do
      {:log, level, message, metadata} ->
        log_fn.(level, message, metadata)
        :ok

      :skip ->
        :ok
    end
  end
end
