defmodule TelemetryLoggerTest do
  use ExUnit.Case, async: false

  setup do
    on_exit(fn ->
      for %{id: {TelemetryLogger, _, _} = id} <- :telemetry.list_handlers([]) do
        :telemetry.detach(id)
      end
    end)
  end

  test "integration test", ctx do
    TelemetryLogger.attach_loggers([TestTelemetryLogger])
    pid = self()
    event = [:telemetry_logger, :test, :event]
    measurements = %{count: 1}
    metadata = %{meta: :data}

    :logger.add_primary_filter(
      ctx.test,
      {fn evt, _arg ->
         if evt.meta.pid == pid do
           send(pid, evt)
           :stop
         else
           :ignore
         end
       end, :ok}
    )

    on_exit(fn -> :logger.remove_primary_filter(ctx.test) end)

    :telemetry.execute(event, measurements, metadata)

    assert_receive %{
      msg: {:string, "Handled Event"},
      meta: %{
        metadata: ^metadata,
        measurements: ^measurements,
        event: ^event
      }
    }
  end

  describe "attach_loggers/1" do
    test "calls init and attaches to :telemetry" do
      assert :ok = TelemetryLogger.attach_loggers([TestTelemetryLogger])
      assert [handler] = :telemetry.list_handlers([:telemetry_logger, :test, :event])
      assert handler.id == {TelemetryLogger, TestTelemetryLogger, []}
      assert handler.config == %{logger_config: %{opts: []}, logger: TestTelemetryLogger}
    end

    test "allows overriding the options" do
      TelemetryLogger.attach_loggers([{TestTelemetryLogger, something: 1234}])

      assert [%{config: %{logger_config: %{opts: [something: 1234]}}}] =
               :telemetry.list_handlers([:telemetry_logger, :test, :event])
    end

    test "raises if config is wrong" do
      assert_raise RuntimeError, ~r/Invalid Logger config/, fn ->
        TelemetryLogger.attach_loggers([{:something, :wrong, :here}])
      end
    end

    test "returns error if one or more handlers are already attached" do
      TelemetryLogger.attach_loggers([
        {TestTelemetryLogger, opt: 1},
        {TestTelemetryLogger, opt: 3},
        {TestTelemetryLogger, opt: 4}
      ])

      assert {:error,
              {:already_exists, [{TestTelemetryLogger, opt: 1}, {TestTelemetryLogger, opt: 3}]}} =
               TelemetryLogger.attach_loggers([
                 {TestTelemetryLogger, opt: 1},
                 {TestTelemetryLogger, opt: 2},
                 {TestTelemetryLogger, opt: 3}
               ])
    end
  end

  describe "handle_event/4" do
    test "calls log function" do
      pid = self()

      TelemetryLogger.handle_event(
        [:event],
        %{measure: 1},
        %{meta: :data},
        %{
          logger: TestTelemetryLogger,
          logger_config: %{opts: []}
        },
        &send(pid, {&1, &2, &3})
      )

      assert_received {:debug, "Handled Event",
                       %{
                         measurements: %{measure: 1},
                         metadata: %{meta: :data},
                         event: [:event],
                         config: %{opts: []}
                       }}
    end

    test "skip logging if handler returns :skip" do
      pid = self()

      TelemetryLogger.handle_event(
        [:event],
        %{},
        %{},
        %{
          logger: TestTelemetryLogger,
          logger_config: %{opts: [skip: true]}
        },
        fn _, _, _ -> send(pid, :log_called) end
      )

      refute_received :log_called
    end
  end
end
