defmodule TramStateMachine do
  @moduledoc """
  This module simulates the behavior of a tram, including its movement between
  stops, door operations, and driver management. It ensures that the tram
  follows safety rules such as not moving with open doors or without a driver.

  States:
  - :in_depot - The tram is in the depot
  - :at_stop  - The tram is at a stop
  - :moving   - The tram is in motion

  Events:
  - leave_depot
  - arrive_at_stop
  - open_doors
  - close_doors
  - start_moving
  - return_to_depot
  - add_driver
  - remove_driver
  """
  use GenServer

  def init(_) do
    {:ok, %{state: :in_depot, doors_open: false, driver_present: false, current_stop: nil}}
  end

  @doc """
  Starts the TramStateMachine GenServer.

  ## Examples

      iex> {:ok, pid} = TramStateMachine.start_link()
      iex> is_pid(pid)
      true
  """
  def start_link do
    GenServer.start_link(__MODULE__, nil)
  end

  @doc """
  Starts the TramStateMachine GenServer with a specific name.

  ## Examples

      iex> {:ok, pid} = TramStateMachine.start_link(:test_tram)
      iex> is_pid(pid)
      true
  """
  def start_link(name) when is_atom(name) do
    GenServer.start_link(__MODULE__, nil, name: name)
  end

  @doc """
  Signals the tram to leave the depot.

  ## Examples

      iex> {:ok, pid} = TramStateMachine.start_link()
      iex> TramStateMachine.add_driver(pid)
      iex> TramStateMachine.leave_depot(pid)
      {:ok, "Tram left the depot"}
  """
  def leave_depot(server \\ __MODULE__), do: GenServer.call(server, :leave_depot)

  @doc """
  Signals the tram to arrive at a stop.

  ## Examples

      iex> {:ok, pid} = TramStateMachine.start_link()
      iex> TramStateMachine.add_driver(pid)
      iex> TramStateMachine.leave_depot(pid)
      iex> TramStateMachine.arrive_at_stop(1, pid)
      {:ok, "Tram arrived at stop 1"}
  """
  def arrive_at_stop(stop, server \\ __MODULE__),
    do: GenServer.call(server, {:arrive_at_stop, stop})

  @doc """
  Opens the tram doors.

  ## Examples

      iex> {:ok, pid} = TramStateMachine.start_link()
      iex> TramStateMachine.add_driver(pid)
      iex> TramStateMachine.leave_depot(pid)
      iex> TramStateMachine.arrive_at_stop(1, pid)
      iex> TramStateMachine.open_doors(pid)
      {:ok, "Doors opened"}
  """
  def open_doors(server \\ __MODULE__), do: GenServer.call(server, :open_doors)

  @doc """
  Closes the tram doors.

  ## Examples

      iex> {:ok, pid} = TramStateMachine.start_link()
      iex> TramStateMachine.add_driver(pid)
      iex> TramStateMachine.leave_depot(pid)
      iex> TramStateMachine.arrive_at_stop(1, pid)
      iex> TramStateMachine.open_doors(pid)
      iex> TramStateMachine.close_doors(pid)
      {:ok, "Doors closed"}
  """
  def close_doors(server \\ __MODULE__), do: GenServer.call(server, :close_doors)

  @doc """
  Starts moving the tram.

  ## Examples

      iex> {:ok, pid} = TramStateMachine.start_link()
      iex> TramStateMachine.add_driver(pid)
      iex> TramStateMachine.leave_depot(pid)
      iex> TramStateMachine.arrive_at_stop(1, pid)
      iex> TramStateMachine.close_doors(pid)
      iex> TramStateMachine.start_moving(pid)
      {:ok, "Tram started moving"}
  """
  def start_moving(server \\ __MODULE__), do: GenServer.call(server, :start_moving)

  @doc """
  Returns the tram to the depot.

  ## Examples

      iex> {:ok, pid} = TramStateMachine.start_link()
      iex> TramStateMachine.add_driver(pid)
      iex> TramStateMachine.leave_depot(pid)
      iex> TramStateMachine.return_to_depot(pid)
      {:ok, "Tram returned to depot"}
  """
  def return_to_depot(server \\ __MODULE__), do: GenServer.call(server, :return_to_depot)

  @doc """
  Adds a driver to the tram.

  ## Examples

      iex> {:ok, pid} = TramStateMachine.start_link()
      iex> TramStateMachine.add_driver(pid)
      {:ok, "Driver added"}
  """
  def add_driver(server \\ __MODULE__), do: GenServer.call(server, :add_driver)

  @doc """
  Removes the driver from the tram.

  ## Examples

      iex> {:ok, pid} = TramStateMachine.start_link()
      iex> TramStateMachine.add_driver(pid)
      iex> TramStateMachine.remove_driver(pid)
      {:ok, "Driver removed"}
  """
  def remove_driver(server \\ __MODULE__), do: GenServer.call(server, :remove_driver)

  def handle_call(
        :leave_depot,
        _from,
        %{state: :in_depot, doors_open: false, driver_present: true} = state
      ) do
    new_state = %{state | state: :moving}
    {:reply, {:ok, "Tram left the depot"}, new_state}
  end

  def handle_call({:arrive_at_stop, stop}, _from, %{state: :moving} = state) do
    new_state = %{state | state: :at_stop, current_stop: stop}
    {:reply, {:ok, "Tram arrived at stop #{stop}"}, new_state}
  end

  def handle_call(:open_doors, _from, %{state: :at_stop, doors_open: false} = state) do
    new_state = %{state | doors_open: true}
    {:reply, {:ok, "Doors opened"}, new_state}
  end

  def handle_call(:close_doors, _from, %{state: :at_stop, doors_open: true} = state) do
    new_state = %{state | doors_open: false}
    {:reply, {:ok, "Doors closed"}, new_state}
  end

  def handle_call(
        :start_moving,
        _from,
        %{state: :at_stop, doors_open: false, driver_present: true} = state
      ) do
    new_state = %{state | state: :moving}
    {:reply, {:ok, "Tram started moving"}, new_state}
  end

  def handle_call(:return_to_depot, _from, %{state: :moving} = state) do
    new_state = %{state | state: :in_depot, current_stop: nil}
    {:reply, {:ok, "Tram returned to depot"}, new_state}
  end

  def handle_call(:add_driver, _from, state) do
    new_state = %{state | driver_present: true}
    {:reply, {:ok, "Driver added"}, new_state}
  end

  def handle_call(:remove_driver, _from, %{state: :in_depot} = state) do
    new_state = %{state | driver_present: false}
    {:reply, {:ok, "Driver removed"}, new_state}
  end

  def handle_call(action, _from, state) do
    {:reply, {:error, "Invalid action #{action} for current state"}, state}
  end
end
