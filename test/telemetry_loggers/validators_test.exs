defmodule TelemetryLoggers.ValidatorsTest do
  use ExUnit.Case

  alias TelemetryLoggers.Validators

  describe "validate_log_level/1" do
    test "returns ok for valid log level" do
      assert :ok = Validators.validate_log_level(:info)
    end

    test "returns error for an invalid log level" do
      assert {:error, :invalid_log_level} = Validators.validate_log_level(:invalid)
    end
  end
end
