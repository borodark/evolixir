defmodule Evolixir.SimulationChamber do
  use ExUnit.Case
  doctest SimulationChamber

  test "Simulate should process generations and return the resulting evolution" do
    actuator_function_id = 1
    actuator_function = fn _cortex_id ->
      fn neural_output ->
        assert neural_output != nil
      end
    end
    actuator_sources = %{
      actuator_function_id => actuator_function
    }

    sync_function_id = 1
    sync_function_source = fn _cortex_id ->
      fn ->
        [1, 2, 3]
      end
    end
    sync_function_sources = %{
      sync_function_id => sync_function_source
    }

    activation_function_id = :sigmoid
    activation_function =
      &ActivationFunction.sigmoid/1
    activation_functions = %{
      activation_function_id => activation_function
    }
    sensor_id = 1
    sensor = %Sensor{
      sensor_id: sensor_id,
      sync_function: sync_function_id
    }

    neuron_id = 2
    neuron = %Neuron{
      neuron_id: neuron_id,
      activation_function: {activation_function_id, activation_function}
    }
    actuator_id = 3
    actuator = %Actuator{
      actuator_id: actuator_id,
      actuator_function: actuator_function_id
    }

    sensors = %{
      sensor.sensor_id => sensor
    }
    neuron_layer = 1
    neurons = %{
      neuron_layer => %{ neuron.neuron_id => neuron }
    }
    actuators = %{
      actuator.actuator_id => actuator
    }

    weight = 0.0
    {:ok, {sensors, neurons}} =
      Sensor.connect_to_neuron(sensors, neurons, sensor_id, neuron_layer, neuron_id, weight)

    {:ok, {neurons, actuators}} =
      Actuator.connect_neuron_to_actuator(neurons, actuators, neuron_layer, neuron_id, actuator_id)

    cortex_id = 1
    neural_network = {sensors, neurons, actuators}
    starting_records = %{
      cortex_id => neural_network
    }

    chamber_name = :simulation_chamber
    minds_per_generation = 5
    possible_mutations = Mutations.default_mutation_sequence

    select_fit_population_function = HyperbolicTimeChamber.get_select_fit_population_function(50)

    fitness_function =
      fn _cortex_id ->
        {:continue_think_cycle, :random.uniform()}
      end

    think_timeout = 5000
    simulation_chamber_properties = %SimulationChamber{
      think_timeout: think_timeout,
      chamber_name: chamber_name,
      fitness_function: fitness_function,
      actuator_sources: actuator_sources,
      sync_sources: sync_function_sources,
      activation_functions: activation_functions,
      minds_per_generation: minds_per_generation,
      possible_mutations: possible_mutations,
      select_fit_population_function: select_fit_population_function,
      starting_generation_records: starting_records
    }

    generations_to_simulate = 50
    {:ok, scored_generation_records} = SimulationChamber.simulate(simulation_chamber_properties, generations_to_simulate)
    assert scored_generation_records != []
  end

  test "If a brain didn't process the simulation, then the chamber should self recover and move on" do
    actuator_function_id = 1
    actuator_function = fn _cortex_id ->
      fn neural_output ->
        assert neural_output != nil
      end
    end
    actuator_sources = %{
      actuator_function_id => actuator_function
    }

    sync_function_id = 1
    sync_function_source = fn _cortex_id ->
      fn ->
        [1, 2, 3]
      end
    end
    sync_function_sources = %{
      sync_function_id => sync_function_source
    }

    activation_function_id = :sigmoid
    activation_function =
      &ActivationFunction.sigmoid/1
    activation_functions = %{
      activation_function_id => activation_function
    }
    sensor_id = 1
    sensor = %Sensor{
      sensor_id: sensor_id,
      sync_function: sync_function_id
    }

    neuron_id = 2
    neuron = %Neuron{
      neuron_id: neuron_id,
      activation_function: {activation_function_id, activation_function}
    }
    actuator_id = 3
    actuator = %Actuator{
      actuator_id: actuator_id,
      actuator_function: actuator_function_id
    }

    sensors = %{
      sensor.sensor_id => sensor
    }
    neuron_layer = 1
    neurons = %{
      neuron_layer => %{ neuron.neuron_id => neuron }
    }
    actuators = %{
      actuator.actuator_id => actuator
    }

    weight = 0.0
    {:ok, {sensors, neurons}} =
      Sensor.connect_to_neuron(sensors, neurons, sensor_id, neuron_layer, neuron_id, weight)

    cortex_id = 1
    neural_network = {sensors, neurons, actuators}
    starting_records = %{
      cortex_id => neural_network
    }

    chamber_name = :simulation_chamber
    minds_per_generation = 5
    possible_mutations = Mutations.default_mutation_sequence

    select_fit_population_function = HyperbolicTimeChamber.get_select_fit_population_function(50)

    fitness_function =
      fn _cortex_id ->
        {:continue_think_cycle, :random.uniform()}
      end

    think_timeout = 10
    simulation_chamber_properties = %SimulationChamber{
      think_timeout: think_timeout,
      chamber_name: chamber_name,
      fitness_function: fitness_function,
      actuator_sources: actuator_sources,
      sync_sources: sync_function_sources,
      activation_functions: activation_functions,
      minds_per_generation: minds_per_generation,
      possible_mutations: possible_mutations,
      select_fit_population_function: select_fit_population_function,
      starting_generation_records: starting_records
    }

    generations_to_simulate = 1
    {:ok, scored_generation_records} = SimulationChamber.simulate(simulation_chamber_properties, generations_to_simulate)
    assert scored_generation_records != []
  end

  test "neural_connection_cost should alter the fitness score by penalizing the amount of connections a solutions has" do
    actuator_function_id = 1
    actuator_function = fn _cortex_id ->
      fn neural_output ->
        assert neural_output != nil
      end
    end
    actuator_sources = %{
      actuator_function_id => actuator_function
    }

    sync_function_id = 1
    sync_function_source = fn _cortex_id ->
      fn ->
        [1, 2, 3]
      end
    end
    sync_function_sources = %{
      sync_function_id => sync_function_source
    }

    activation_function_id = :sigmoid
    activation_function =
      &ActivationFunction.sigmoid/1
    activation_functions = %{
      activation_function_id => activation_function
    }
    sensor_id = 1
    sensor = %Sensor{
      sensor_id: sensor_id,
      sync_function: sync_function_id
    }

    neuron_id = 2
    neuron = %Neuron{
      neuron_id: neuron_id,
      activation_function: {activation_function_id, activation_function}
    }
    actuator_id = 3
    actuator = %Actuator{
      actuator_id: actuator_id,
      actuator_function: actuator_function_id
    }

    sensors = %{
      sensor.sensor_id => sensor
    }
    neuron_layer = 1
    neurons = %{
      neuron_layer => %{ neuron.neuron_id => neuron }
    }
    actuators = %{
      actuator.actuator_id => actuator
    }

    weight = 0.0
    {:ok, {sensors, neurons}} =
      Sensor.connect_to_neuron(sensors, neurons, sensor_id, neuron_layer, neuron_id, weight)

    {:ok, {neurons, actuators}} =
      Actuator.connect_neuron_to_actuator(neurons, actuators, neuron_layer, neuron_id, actuator_id)

    cortex_id = 1
    neural_network = {sensors, neurons, actuators}
    starting_records = %{
      cortex_id => neural_network
    }

    chamber_name = :simulation_chamber
    minds_per_generation = 4
    possible_mutations = Mutations.default_mutation_sequence

    select_fit_population_function = HyperbolicTimeChamber.get_select_fit_population_function(50)

    default_score = 10
    end_of_life_cycle_score = default_score * 5
    fitness_function =
      fn _cortex_id ->
        {:continue_think_cycle, default_score}
      end

    neural_connection_cost = 1

    calculate_neuron_connection_cost = fn {_neuron_id, neuron} ->
      total_connections = neuron.inbound_connections |> Enum.count
      total_connections * neural_connection_cost
    end

    end_of_generation_function =
      fn scored_generation_records ->
        {score, _cortex_id, {_sensors, neurons, _actuators}} = scored_generation_records |> List.first
        total_connection_cost =
          neurons
          |> Enum.map(fn {_neuron_layer, neurons} ->
            neurons
            |> Enum.map(calculate_neuron_connection_cost)
            |> Enum.sum
          end)
          |> Enum.sum
        assert score == (end_of_life_cycle_score - total_connection_cost)
        :ok
      end

    think_timeout = 5000
    simulation_chamber_properties = %SimulationChamber{
      think_timeout: think_timeout,
      chamber_name: chamber_name,
      fitness_function: fitness_function,
      actuator_sources: actuator_sources,
      sync_sources: sync_function_sources,
      activation_functions: activation_functions,
      minds_per_generation: minds_per_generation,
      possible_mutations: possible_mutations,
      select_fit_population_function: select_fit_population_function,
      starting_generation_records: starting_records,
      neural_connection_cost: neural_connection_cost,
      end_of_generation_function: end_of_generation_function
    }

    generations_to_simulate = 50
    {:ok, scored_generation_records} = SimulationChamber.simulate(simulation_chamber_properties, generations_to_simulate)
    assert scored_generation_records != []
  end

  #TODO add before_generation_function test

end
