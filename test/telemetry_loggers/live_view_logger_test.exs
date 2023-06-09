defmodule TelemetryLoggers.LiveViewLoggerTest do
  @moduledoc false

  use ExUnit.Case

  alias TelemetryLoggers.LiveViewLogger

  describe "init/1" do
    test "returns events to listen to and config" do
      assert {:ok, events, %{level: :info, router: TestRouter}} =
               LiveViewLogger.init(router: TestRouter)

      assert [
               [:phoenix, :live_view, :mount, :stop],
               [:phoenix, :live_view, :handle_params, :stop],
               [:phoenix, :live_view, :handle_event, :stop],
               [:phoenix, :live_component, :handle_event, :stop]
             ] = events
    end

    test "can override level" do
      {:ok, _events, %{level: :error}} = LiveViewLogger.init(router: TestRouter, level: :error)
    end

    test "check if level is a valid log level" do
      assert {:error, :invalid_log_level} =
               LiveViewLogger.init(router: TestRouter, level: :invalid)
    end
  end

  describe "handle_event/4" do
    test "logs the result with all relevant metadata" do
      duration_us = System.convert_time_unit(20_000_000, :native, :microsecond)

      assert {:log, :info, "live_view -> mount", %{action: :stop, event: "", callback: :mount}} =
               handle_live_view_mount_stop(duration: duration_us)
    end

    test "logs the result when is a live_component" do
      assert {:log, :info, "live_component -> handle_event", %{action: :stop}} =
        handle_live_view_mount_stop(prefix: [:phoenix, :live_component, :handle_event, :stop])
    end

    test "logs the result when exception happened" do
      assert {:log, :info, "live"}
    end
  end

  defp handle_live_view_mount_stop(opts) do
    duration = Keyword.get(opts, :duration, 1)
    prefix = Keyword.get(opts, :prefix, [:phoenix, :live_view, :mount, :stop])

    {:ok, _, config} = LiveViewLogger.init(router: TestRouter)

    LiveViewLogger.handle_event(
      prefix,
      %{duration: duration},
      %{},
      config
    )
  end
end
