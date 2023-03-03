defmodule TelemetryLoggers.PlugLoggerTest do
  use ExUnit.Case
  import Phoenix.ConnTest
  import Plug.Conn

  alias TelemetryLoggers.PlugLogger

  describe "init/1" do
    test "returns events to listen to and config" do
      assert {:ok, events, %{level: :info, router: TestRouter, include_path: true}} =
               PlugLogger.init(router: TestRouter)

      assert [:phoenix, :endpoint, :stop] in events
    end

    test "can override level" do
      assert {:ok, _events, %{level: :error}} = PlugLogger.init(level: :error)
    end

    test "check if level is a valid log level" do
      assert {:error, :invalid_log_level} = PlugLogger.init(level: :whatever)
    end

    test "can hide path" do
      assert {:ok, _, %{level: :info, include_path: false}} = PlugLogger.init(include_path: false)
    end

    test "can override the prefix" do
      assert {:ok, events, _} = PlugLogger.init(prefix: [:my, :plug])

      assert [:my, :plug, :stop] in events
    end
  end

  describe "handle_event/4" do
    test "logs the result of the request with all relevant metadata" do
      duration_us = System.convert_time_unit(20_000_000, :native, :microsecond)

      conn =
        :get
        |> build_conn("/resource/12345")
        |> Map.put(:remote_ip, {127, 0, 0, 1})
        |> put_status(200)

      assert {:log, :info, "GET /resource/12345 -> 200",
              %{
                duration_us: ^duration_us,
                route: "/resource/:id",
                path: "/resource/12345",
                remote_ip: "127.0.0.1",
                route_plug: TestController,
                route_plug_opts: :action,
                method: "GET",
                status: 200
              }} = handle_phoenix_endpoint_stop(conn, duration: 20_000_000, router: TestRouter)
    end

    test "works with ipv6 address" do
      conn =
        :get
        |> build_conn("/resource/12345")
        |> Map.put(:remote_ip, {0, 0, 0, 0, 0, 0, 0, 1})
        |> put_status(200)

      assert {:log, :info, _, %{remote_ip: "::1"}} =
               handle_phoenix_endpoint_stop(conn, duration: 20_000_000, router: TestRouter)
    end

    test "works if route does not exist" do
      conn =
        :get
        |> build_conn("/invalid_route")
        |> put_status(404)

      assert {:log, :info, "GET /invalid_route -> 404", metadata} =
               handle_phoenix_endpoint_stop(conn)

      refute Map.has_key?(metadata, :route)
    end

    test "works if include_path is false and route does not exist" do
      conn =
        :get
        |> build_conn("/invalid_route")
        |> put_status(404)

      assert {:log, :info, "GET nil -> 404", metadata} =
               handle_phoenix_endpoint_stop(conn, include_path: false)

      refute Map.has_key?(metadata, :route)
    end

    test "shows route if include_path is false and router is passed" do
      conn =
        :get
        |> build_conn("/resource/12345")
        |> put_status(200)

      assert {:log, :info, "GET /resource/:id -> 200", metadata} =
               handle_phoenix_endpoint_stop(conn, include_path: false, router: TestRouter)

      refute Map.has_key?(metadata, :path)
    end

    test "works when there is no router and include_path is false" do
      conn =
        :get
        |> build_conn("/resource/12345")
        |> put_status(200)

      assert {:log, :info, "GET nil -> 200", %{status: 200}} =
               handle_phoenix_endpoint_stop(conn, include_path: false)
    end
  end

  defp handle_phoenix_endpoint_stop(conn, opts \\ []) do
    {duration, opts} = Keyword.pop(opts, :duration, 1)

    opts =
      if is_nil(Keyword.get(opts, :router)) do
        Keyword.delete(opts, :router)
      else
        opts
      end

    {:ok, _, config} = PlugLogger.init(opts)

    PlugLogger.handle_event(
      [:phoenix, :endpoint, :stop],
      %{duration: duration},
      %{conn: conn},
      config
    )
  end
end
