defmodule TramStateMachineTest do
  use ExUnit.Case
  doctest TramStateMachine

  setup do
    {:ok, pid} = TramStateMachine.start_link()

    on_exit(fn ->
      if Process.alive?(pid), do: GenServer.stop(pid)
    end)

    %{tram: pid}
  end

  test "initial state is in depot", %{tram: tram} do
    assert :sys.get_state(tram) == %{
             state: :in_depot,
             doors_open: false,
             driver_present: false,
             current_stop: nil
           }
  end

  test "can't leave depot without driver", %{tram: tram} do
    assert {:error, _} = TramStateMachine.leave_depot(tram)
  end

  test "can leave depot with driver", %{tram: tram} do
    TramStateMachine.add_driver(tram)
    assert {:ok, _} = TramStateMachine.leave_depot(tram)
    assert :sys.get_state(tram).state == :moving
  end

  test "can arrive at stop", %{tram: tram} do
    TramStateMachine.add_driver(tram)
    TramStateMachine.leave_depot(tram)
    assert {:ok, _} = TramStateMachine.arrive_at_stop(1, tram)
    assert :sys.get_state(tram).state == :at_stop
    assert :sys.get_state(tram).current_stop == 1
  end

  test "can open and close doors at stop", %{tram: tram} do
    TramStateMachine.add_driver(tram)
    TramStateMachine.leave_depot(tram)
    TramStateMachine.arrive_at_stop(1, tram)
    assert {:ok, _} = TramStateMachine.open_doors(tram)
    assert :sys.get_state(tram).doors_open == true
    assert {:ok, _} = TramStateMachine.close_doors(tram)
    assert :sys.get_state(tram).doors_open == false
  end

  test "can't start moving with open doors", %{tram: tram} do
    TramStateMachine.add_driver(tram)
    TramStateMachine.leave_depot(tram)
    TramStateMachine.arrive_at_stop(1, tram)
    TramStateMachine.open_doors(tram)
    assert {:error, _} = TramStateMachine.start_moving(tram)
  end

  test "can start moving with closed doors", %{tram: tram} do
    TramStateMachine.add_driver(tram)
    TramStateMachine.leave_depot(tram)
    TramStateMachine.arrive_at_stop(1, tram)
    TramStateMachine.close_doors(tram)
    assert {:ok, _} = TramStateMachine.start_moving(tram)
    assert :sys.get_state(tram).state == :moving
  end

  test "can return to depot", %{tram: tram} do
    TramStateMachine.add_driver(tram)
    TramStateMachine.leave_depot(tram)
    assert {:ok, _} = TramStateMachine.return_to_depot(tram)
    assert :sys.get_state(tram).state == :in_depot
    assert :sys.get_state(tram).current_stop == nil
  end

  test "can't remove driver while not in depot", %{tram: tram} do
    TramStateMachine.add_driver(tram)
    TramStateMachine.leave_depot(tram)
    assert {:error, _} = TramStateMachine.remove_driver(tram)
  end

  test "can remove driver in depot", %{tram: tram} do
    TramStateMachine.add_driver(tram)
    assert {:ok, _} = TramStateMachine.remove_driver(tram)
    assert :sys.get_state(tram).driver_present == false
  end
end
