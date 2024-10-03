defmodule TramStateMachineTest do
  use ExUnit.Case
  doctest TramStateMachine

  test "greets the world" do
    assert TramStateMachine.hello() == :world
  end
end
