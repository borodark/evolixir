defmodule Evolixir.ActuatorTest do
  use ExUnit.Case
  doctest Actuator

  test "calculate_output_value should sum barrier" do
    barrier = %{
      {1, 4} => %Synapse{value: 4},
      {5, 2} => %Synapse{value: 1},
      {6, 3} => %Synapse{value: 1},
    }
    output_value = Actuator.calculate_output_value(barrier)
    assert output_value == 6
  end

  test ":receive_synapse should activate Actuator if barrier is full" do
    {:ok, actuator_test_helper_pid} = GenServer.start_link(NodeTestHelper, %NodeTestHelper{})
    fake_node_pid = 9

    actuator_function =
    {0, fn output_value ->
      :ok = GenServer.call(actuator_test_helper_pid, {:activate, output_value})
    end}

    {:ok, {inbound_connections, connection_id}} =
      NeuralNode.add_inbound_connection(Map.new(), fake_node_pid, 0.0)

    {:ok, actuator_pid} = GenServer.start_link(Actuator,
      %Actuator{
        actuator_function: actuator_function,
        inbound_connections: inbound_connections
      })

    artificial_synapse = %Synapse{
      connection_id: connection_id,
      from_node_id: fake_node_pid,
      value: 1.5
    }
    GenServer.cast(actuator_pid, {:receive_synapse, artificial_synapse})

    :timer.sleep(5)
    updated_test_state = GenServer.call(actuator_test_helper_pid, :get_state)

    {true, activated_value} = updated_test_state.was_activated
    assert activated_value == artificial_synapse.value
  end

  test ":receive_synapse should activate Actuator if barrier is full with two expected inbound connections" do
    {:ok, actuator_test_helper_pid} = GenServer.start_link(NodeTestHelper, %NodeTestHelper{})

    actuator_function =
    {0, fn output_value ->
      :ok = GenServer.call(actuator_test_helper_pid, {:activate, output_value})
    end}

    fake_node_pid = 9
    {:ok, {inbound_connections_count_one, connection_id}} =
      NeuralNode.add_inbound_connection(Map.new(), fake_node_pid, 0.0)
    {:ok, {inbound_connections, connection_id_two}} =
      NeuralNode.add_inbound_connection(inbound_connections_count_one, fake_node_pid, 0.0)

    {:ok, actuator_pid} = GenServer.start_link(Actuator,
      %Actuator{
        actuator_function: actuator_function,
        inbound_connections: inbound_connections
      })


    artificial_synapse = %Synapse{
      connection_id: connection_id,
      from_node_id: fake_node_pid,
      value: 1.5
    }
    artificial_synapse_two = %Synapse{
      connection_id: connection_id_two,
      from_node_id: fake_node_pid,
      value: 4.9
    }
    GenServer.cast(actuator_pid, {:receive_synapse, artificial_synapse})
    GenServer.cast(actuator_pid, {:receive_synapse, artificial_synapse_two})

    :timer.sleep(5)
    updated_test_state = GenServer.call(actuator_test_helper_pid, :get_state)

    {true, activated_value} = updated_test_state.was_activated
    expected_value = artificial_synapse.value + artificial_synapse_two.value
    assert_in_delta activated_value, expected_value, 0.001
  end

  test ":receive_blank_synapse should not activate Actuator if barrier is full" do
    {:ok, actuator_test_helper_pid} = GenServer.start_link(NodeTestHelper, %NodeTestHelper{})

    actuator_function =
    {0, fn output_value ->
      :ok = GenServer.call(actuator_test_helper_pid, {:activate, output_value})
    end}

    fake_node_pid = 4

    {:ok, {inbound_connections, connection_id}} =
      NeuralNode.add_inbound_connection(Map.new(), fake_node_pid, 0.0)

    {:ok, actuator_pid} = GenServer.start_link(Actuator,
      %Actuator{
        actuator_function: actuator_function,
        inbound_connections: inbound_connections
      })

    artificial_synapse = %Synapse{
      connection_id: connection_id,
      from_node_id: fake_node_pid,
      value: 1.5
    }
    GenServer.cast(actuator_pid, {:receive_blank_synapse, artificial_synapse})

    :timer.sleep(5)
    updated_test_state = GenServer.call(actuator_test_helper_pid, :get_state)

    assert updated_test_state.was_activated == false
  end

  test ":receive_blank_synapse should not activate Actuator if barrier is full with two inbound connections" do
    {:ok, actuator_test_helper_pid} = GenServer.start_link(NodeTestHelper, %NodeTestHelper{})

    actuator_function =
    {0, fn output_value ->
      :ok = GenServer.call(actuator_test_helper_pid, {:activate, output_value})
    end}

    fake_node_pid = 75

    {:ok, {inbound_connections_count_one, connection_id}} =
      NeuralNode.add_inbound_connection(Map.new(), fake_node_pid, 0.0)
    {:ok, {inbound_connections, connection_id_two}} =
      NeuralNode.add_inbound_connection(inbound_connections_count_one, fake_node_pid, 0.0)

    {:ok, actuator_pid} = GenServer.start_link(Actuator,
      %Actuator{
        actuator_function: actuator_function,
        inbound_connections: inbound_connections
      })

    artificial_synapse = %Synapse{
      connection_id: connection_id,
      from_node_id: fake_node_pid,
      value: 1.5
    }
    artificial_synapse_two = %Synapse{
      connection_id: connection_id_two,
      from_node_id: fake_node_pid,
      value: 3.6
    }
    GenServer.cast(actuator_pid, {:receive_blank_synapse, artificial_synapse})
    GenServer.cast(actuator_pid, {:receive_blank_synapse, artificial_synapse_two})

    :timer.sleep(5)
    updated_test_state = GenServer.call(actuator_test_helper_pid, :get_state)

    assert updated_test_state.was_activated == false
  end

  test "connect_neuron_to_actuator should connect a neuron to an actuator" do
    neuron_id = 1
    neuron = %Neuron{neuron_id: neuron_id}
    neuron_layer = 1
    {:ok, neurons} = Neuron.add_to_neural_layer(neuron_layer, [neuron])
    actuator_id = 2
    actuator = %Actuator{actuator_id: actuator_id}
    actuators = %{actuator_id => actuator}
    {:ok, {neurons, actuators}} = Actuator.connect_neuron_to_actuator(neurons, actuators, neuron_layer, neuron_id, actuator_id)
    {:ok, neuron} = Neuron.get_neuron(neurons, neuron_layer, neuron_id)
    {:ok, actuator} = Actuator.get_actuator(actuators, actuator_id)
    connection_id = 1
    assert Enum.count(neuron.outbound_connections) == 1
    assert Map.has_key?(neuron.outbound_connections, {actuator_id, connection_id}) == true
    assert Enum.count(actuator.inbound_connections) == 1
    assert Map.has_key?(actuator.inbound_connections, neuron_id) == true
    connections_from_neuron = Map.get(actuator.inbound_connections, neuron_id)
    assert Map.has_key?(connections_from_neuron, connection_id)
  end

end
