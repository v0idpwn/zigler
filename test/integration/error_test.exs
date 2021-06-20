defmodule ZiglerTest.Integration.ErrorTest do
  use ExUnit.Case, async: true
  use Zig, link_libc: true

  ~Z"""
  /// nif: void_error/1
  fn void_error(input: i64) !void {
    if (input != 47) {
      return error.BadInput;
    }
  }

  /// nif: nested_error/1
  fn nested_error(input: i64) !void {
    return void_error(input);
  }

  /// nif: union_error/1
  fn union_error(input: i64) !i64 {
    if (input == 42) {
      return error.BadInput;
    }
    return input;
  }
  """

  def foo do
    raise __MODULE__.ZigError, message: "foo", error_return_trace: []
  end

  test "for the void error case" do
    assert nil == void_error(47)

    {error, stacktrace} =
      try do
        void_error(42)
      rescue
        error in __MODULE__.ZigError ->
          Exception.blame(:error, error, __STACKTRACE__)
      end

    assert Exception.message(error) == "#{inspect __MODULE__}.void_error/1 returned the zig error `.BadInput`"

    assert [{
      :zig, :void_error, '*',
    [
      file: "/tmp/.zigler_compiler/test/Elixir.ZiglerTest.Integration.ErrorTest/Elixir.ZiglerTest.Integration.ErrorTest.zig",
      line: 9
    ]} | _] = stacktrace
  end

  test "for the nested error case" do
    assert nil == nested_error(47)

    {error, stacktrace} =
      try do
        nested_error(42)
      rescue
        error in __MODULE__.ZigError ->
          Exception.blame(:error, error, __STACKTRACE__)
      end

    assert Exception.message(error) == "#{inspect __MODULE__}.nested_error/1 returned the zig error `.BadInput`"

    assert [{
      :zig, :void_error, '*',
    [
      file: "/tmp/.zigler_compiler/test/Elixir.ZiglerTest.Integration.ErrorTest/Elixir.ZiglerTest.Integration.ErrorTest.zig",
      line: 9
    ]}, {
      :zig, :nested_error, '*',
    [
      file: "/tmp/.zigler_compiler/test/Elixir.ZiglerTest.Integration.ErrorTest/Elixir.ZiglerTest.Integration.ErrorTest.zig",
      line: 15
    ]} | _] = stacktrace
  end

  test "for the error set union case" do
    assert 47 == union_error(47)

    {error, stacktrace} =
      try do
        union_error(42)
      rescue
        error in __MODULE__.ZigError ->
          Exception.blame(:error, error, __STACKTRACE__)
      end

    assert Exception.message(error) == "#{inspect __MODULE__}.union_error/1 returned the zig error `.BadInput`"

    assert [{
      :zig, :union_error, '*',
    [
      file: "/tmp/.zigler_compiler/test/Elixir.ZiglerTest.Integration.ErrorTest/Elixir.ZiglerTest.Integration.ErrorTest.zig",
      line: 21
    ]} | _] = stacktrace
  end

  @tag :skip
  test "for threaded"

  @tag :skip
  test "for yielding"
end