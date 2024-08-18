extends Node

# Node references
@export var weather_manager: Node
@export var solar_calculator: Node
@export var time_manager: Node
@export var ui_manager: Node
@export var solar_panel: Node
@export var wind_turbine: Node
@export var battery: Node
@export var human_population: Node
@export var ha_connector: Node
@export var ha_device_manager: Node
@export var godot_sky: WorldEnvironment

# Simulation variables
var simulation_running: bool = false
var reverse_simulation: bool = false
var is_live_mode: bool = false
var timer: Timer = null
var previous_solar_total: float = 0.0
var total_rain_accumulated: float = 0.0
var last_update_index: int = -1
var time_passed: float = 0.0
var sky_tween: Tween
var current_sky_time: float = 0.0
const MIN_TRANSITION_TIME: float = 0.05  # Minimum transition time in seconds
const MAX_TRANSITION_TIME: float = 0.5   # Maximum transition time in seconds

func _ready():
#	setup_sky_tween()
	print("Main: Ready function called")
	if check_node_assignments():
		setup_managers()
		connect_signals()
		if ui_manager:
			ui_manager.setup()
		initialize_home_assistant()
	else:
		print("Main: Some required nodes are missing. Please check node assignments in the Inspector.")
#func setup_sky_tween():
#	sky_tween = create_tween()
#	sky_tween.set_loops()
#	sky_tween.connect("step_finished", Callable(self, "_on_sky_tween_step_finished"))

func check_node_assignments() -> bool:
	var all_nodes_assigned = true
	var node_names = ["weather_manager", "solar_calculator", "time_manager", "ui_manager", 
					  "solar_panel", "wind_turbine", "battery", "human_population", 
					  "ha_connector", "ha_device_manager", "godot_sky"]
	
	for node_name in node_names:
		if get(node_name) == null:
			print("Main: " + node_name + " is not assigned. Please assign it in the Inspector.")
			all_nodes_assigned = false
	
	return all_nodes_assigned

func setup_managers():
	print("Main: Setting up managers")
	if time_manager:
		time_manager.setup()

func connect_signals():
	print("Main: Connecting signals")
	if weather_manager:
		weather_manager.connect("weather_data_loaded", Callable(self, "_on_weather_manager_weather_data_loaded"))
		weather_manager.connect("weather_data_load_failed", Callable(self, "_on_weather_manager_weather_data_load_failed"))
	
	if ui_manager:
		ui_manager.connect("play_pressed", Callable(self, "_on_ui_manager_play_pressed"))
		ui_manager.connect("pause_pressed", Callable(self, "_on_ui_manager_pause_pressed"))
		ui_manager.connect("reverse_pressed", Callable(self, "_on_ui_manager_reverse_pressed"))
		ui_manager.connect("timescale_changed", Callable(self, "_on_ui_manager_timescale_changed"))
		ui_manager.connect("timeline_changed", Callable(self, "_on_ui_manager_timeline_changed"))
		ui_manager.connect("device_placed", Callable(self, "_on_ui_manager_device_placed"))
	
	if ha_connector:
		ha_connector.connect("connected", Callable(self, "_on_ha_connector_connected"))
		ha_connector.connect("disconnected", Callable(self, "_on_ha_connector_disconnected"))
		ha_connector.connect("data_received", Callable(self, "_on_ha_connector_data_received"))
		ha_connector.connect("devices_received", Callable(self, "_on_ha_connector_devices_received"))
	
	if ha_device_manager:
		ha_device_manager.connect("device_added", Callable(self, "_on_ha_device_manager_device_added"))
		ha_device_manager.connect("device_removed", Callable(self, "_on_ha_device_manager_device_removed"))
		ha_device_manager.connect("device_state_changed", Callable(self, "_on_ha_device_manager_device_state_changed"))
		
	if human_population:
		human_population.connect("resources_consumed", Callable(self, "_on_human_population_resources_consumed"))
		human_population.connect("waste_generated", Callable(self, "_on_human_population_waste_generated"))
		human_population.connect("economic_update", Callable(self, "_on_human_population_economic_update"))

	if solar_panel:
		solar_panel.connect("energy_generated", Callable(self, "_on_solar_panel_energy_generated"))
	if wind_turbine:
		wind_turbine.connect("energy_generated", Callable(self, "_on_wind_turbine_energy_generated"))

func initialize_home_assistant():
	print("Main: Initializing Home Assistant")
	if ha_device_manager:
		if not ha_device_manager.devices:
			ha_device_manager.devices = {}
		if not ha_device_manager.device_data_log:
			ha_device_manager.device_data_log = {}
	
	if ha_connector:
		if not ha_connector.devices:
			ha_connector.devices = {}
	
	ui_manager.update_device_list(ha_connector.devices if ha_connector else {}, 
								  ha_device_manager.devices if ha_device_manager else {})

func _on_weather_manager_weather_data_loaded():
	print("Main: Weather data loaded successfully")
	# You might want to enable UI elements or start the simulation here

func _on_weather_manager_weather_data_load_failed():
	print("Main: Failed to load weather data")
	# You might want to show an error message to the user or disable certain UI elements

func _on_ui_manager_play_pressed():
	print("Main: Play button pressed")
	if not simulation_running:
		print("Main: Starting simulation")
		simulation_running = true
		reverse_simulation = false
		start_simulation()
	else:
		print("Main: Simulation is already running")

func _on_ui_manager_pause_pressed():
	print("Main: Pause button pressed")
	simulation_running = false
	if timer:
		timer.stop()
	ui_manager.update_play_button_state(false)

func _on_ui_manager_reverse_pressed():
	print("Main: Reverse button pressed")
	if not simulation_running:
		simulation_running = true
		reverse_simulation = true
		start_simulation()

func _on_ui_manager_timescale_changed(value):
	print("Main: Timescale changed to ", value)
	time_manager.set_time_scale(value)
	if value < 0:
		reverse_simulation = true
	else:
		reverse_simulation = false
	
	if simulation_running:
		if timer:
			timer.stop()
		start_simulation()

func _on_ui_manager_timeline_changed(value):
	print("Main: Timeline changed to ", value)
	time_manager.set_current_index(int(value))
	update_simulation(0.0)

func start_simulation():
	print("Main: Entering start_simulation function")
	if timer:
		print("Main: Stopping existing timer")
		timer.stop()
	
	if not weather_manager:
		print("Main: Weather manager is null")
		return
	if not weather_manager.has_weather_data():
		print("Main: No weather data available")
		ui_manager.show_error("No weather data available. Please load weather data before starting the simulation.")
		simulation_running = false
		return
	
	print("Main: Creating new timer")
	timer = Timer.new()
	var time_scale = time_manager.get_time_scale()
	if time_scale == 0:
		print("Main: Time scale is 0, setting to 1")
		time_scale = 1
	timer.set_wait_time(1.0 / abs(time_scale))
	timer.set_one_shot(false)
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(timer)
	timer.start()
	print("Main: Timer started with wait time ", timer.get_wait_time())
	
	time_passed = 0.0  # Reset accumulated time
	last_update_index = -1  # Reset last_update_index
	update_simulation(0.0)  # Update immediately instead of waiting for first timeout
	update_godot_sky()  # Update GodotSky immediately
	ui_manager.update_play_button_state(true)

func _on_timer_timeout():
	print("Main: Timer timeout")
	if not weather_manager or not time_manager:
		print("Main: Weather manager or time manager not available")
		return
	
	var time_scale = time_manager.get_time_scale()
	time_passed += 1.0 * abs(time_scale)  # Accumulate time passed in seconds
	
	if time_passed >= 3600.0:  # If an hour or more has passed
		var hours_passed = floor(time_passed / 3600.0)
		time_manager.advance_time(hours_passed)
		update_simulation(hours_passed * 3600.0)
		time_passed -= hours_passed * 3600.0  # Subtract the processed time
	
	update_godot_sky()


func update_simulation(delta_time: float):
	print("Main: Updating simulation")
	var current_index = time_manager.get_current_index()
	
	# Only update if the index has changed
	if current_index != last_update_index:
		var weather_data = weather_manager.get_weather_at_index(current_index)
		if weather_data == null:
			print("Main: No weather data available for index ", current_index)
			return
		
		var date_time = time_manager.get_current_date_time()
		ui_manager.update_weather_display(weather_data)
		ui_manager.update_date_time(date_time)
		update_solar_output(delta_time)
		update_wind_output(weather_data["windspeed"], delta_time)
		update_human_population(delta_time)
		
		var total_solar = solar_panel.get_energy_generated()
		var total_wind = wind_turbine.get_total_energy_generated()
		ui_manager.update_totals(
			weather_data["precipitation"],
			ui_manager.get_rain_area(),
			total_solar,
			total_wind
		)
		
		if ui_manager and ui_manager.has_method("update_timeline"):
			ui_manager.update_timeline(current_index)
		else:
			print("Main: UIManager doesn't have update_timeline method")
		
		last_update_index = current_index
		print("Main: Update completed for index ", current_index)
	else:
		print("Main: Skipping update, index hasn't changed")
		
func update_solar_output(delta_time: float):
	print("Main: Entering update_solar_output")
	if not solar_panel or not solar_calculator or not time_manager or not ui_manager:
		print("Main: Required components not found")
		return
	
	var solar_parameters = ui_manager.get_solar_parameters()
	print("Main: Solar parameters: ", solar_parameters)
	
	var day_of_year = time_manager.get_day_of_year()
	var hour = time_manager.get_hour()
	print("Main: Calculating for day %d, hour %d" % [day_of_year, hour])
	
	var solar_output = solar_calculator.calculate_solar_output(
		day_of_year,
		hour,
		solar_parameters
	)
	
	print("Main: Calculated hourly solar output: %.3f Wh" % solar_output)
	
	ui_manager.update_solar_output(solar_output)  # Display hourly output in Wh
	
	var hours = delta_time / 3600.0
	print("Main: Time step in hours: %.6f" % hours)
	var energy_generated_kwh = (solar_output * hours) / 1000.0  # Convert to kWh
	print("Main: Energy generated this step: %.6f kWh" % energy_generated_kwh)
	
	if reverse_simulation:
		solar_panel.subtract_energy_generated(energy_generated_kwh)
	else:
		solar_panel.update_energy_generation(energy_generated_kwh)
	
	var total_solar = solar_panel.get_energy_generated()
	print("Main: Total solar energy after update: %.3f kWh" % total_solar)
	
	ui_manager.update_totals(
		weather_manager.get_weather_at_index(time_manager.get_current_index())["precipitation"],
		ui_manager.get_rain_area(),
		total_solar,
		wind_turbine.get_total_energy_generated()
	)
	
func update_wind_output(wind_speed, delta_time: float):
	print("Main: Updating wind output")
	var hours = delta_time / 3600.0
	wind_turbine.update_energy_generation(wind_speed, hours)
	var wind_energy = wind_turbine.get_total_energy_generated()
	ui_manager.update_wind_output(wind_energy)

func update_human_population(delta_time: float):
	print("Debug: Updating human population")
	human_population.update_simulation(delta_time)
	var consumption = human_population.get_total_consumption()
	var waste = human_population.get_total_waste()
	var economic_data = human_population.get_economic_data()
	ui_manager.update_human_population(consumption, waste, economic_data)

func update_totals(weather_data):
	print("Main: Updating totals")
	var rain_area = ui_manager.get_rain_area()
	var precipitation = weather_data["precipitation"]
	var solar_energy = solar_panel.get_energy_generated()
	var wind_energy = wind_turbine.get_total_energy_generated()
	
	# Accumulate rain
	var hourly_rain = precipitation * rain_area
	if reverse_simulation:
		total_rain_accumulated = max(0, total_rain_accumulated - hourly_rain)
	else:
		total_rain_accumulated += hourly_rain
	
	print("Main: Total rain accumulated: %.1f L" % total_rain_accumulated)
	ui_manager.update_totals(total_rain_accumulated, solar_energy, wind_energy, reverse_simulation)



func update_godot_sky():
	if godot_sky:
		var current_hour = time_manager.get_hour()
		var current_minute = (time_manager.get_current_index() % 60)
		var target_time = current_hour + (current_minute / 60.0)
		
		# Calculate the shortest path to the target time (considering day wrap)
		var diff = fposmod(target_time - current_sky_time + 12, 24) - 12
		var new_time = current_sky_time + diff
		
		# Calculate transition duration based on time scale
		var time_scale = abs(time_manager.get_time_scale())
		var transition_duration = clamp(1.0 / time_scale, MIN_TRANSITION_TIME, MAX_TRANSITION_TIME)
		
		# Get current cloudcover
		var weather_data = weather_manager.get_weather_at_index(time_manager.get_current_index())
		var target_cloudcover = weather_data["cloudcover"] if "cloudcover" in weather_data else 0.0
		
		# Create and start a new tween
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_LINEAR)
		tween.set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(self, "current_sky_time", new_time, transition_duration)
		tween.parallel().tween_property(godot_sky, "cloudCoverage", target_cloudcover, transition_duration)
		tween.tween_callback(Callable(self, "_on_sky_tween_completed"))
		
		print("Main: Updating GodotSky time from %.2f to %.2f (duration: %.3f s)" % [current_sky_time, new_time, transition_duration])
		print("Main: Updating cloudcover to %.2f" % target_cloudcover)

func _on_sky_tween_completed():
	if godot_sky:
		var time_of_day = int(fposmod(current_sky_time, 24) * 100)
		godot_sky.update_time_of_day(time_of_day)
		print("Main: GodotSky time updated to ", time_of_day)

func _process(delta):
	if godot_sky:
		var time_of_day = int(fposmod(current_sky_time, 24) * 100)
		godot_sky.update_time_of_day(time_of_day)


func _on_ha_connector_connected():
	print("Main: Connected to Home Assistant")
	ui_manager.update_connection_status(true)

func _on_ha_connector_disconnected():
	print("Main: Disconnected from Home Assistant")
	ui_manager.update_connection_status(false)

func _on_ha_device_manager_device_added(device_id, godot_object):
	print("Main: Device added:", device_id)
	ui_manager.update_device_list(ha_connector.devices, ha_device_manager.devices)

func _on_ha_device_manager_device_removed(device_id):
	print("Main: Device removed:", device_id)
	ui_manager.update_device_list(ha_connector.devices, ha_device_manager.devices)

func _on_ui_manager_device_placed(device_id, position):
	print("Main: Device placed:", device_id, "at position:", position)
	ha_device_manager.add_device(ha_connector.devices[device_id])
	ui_manager.update_device_list(ha_connector.devices, ha_device_manager.devices)

func _on_ha_connector_data_received(entity_id, state):
	print("Main: Received data from Home Assistant - Entity: ", entity_id, " State: ", state)
	# Add logic to handle the received data

func _on_ha_connector_devices_received(devices):
	print("Main: Received devices from Home Assistant")
	# Add logic to handle the received devices

func _on_ha_device_manager_device_state_changed(device_id, state):
	print("Main: Device state changed - Device: ", device_id, " New state: ", state)
	# Add logic to handle the device state change

func _on_solar_panel_energy_generated(amount):
	print("Main: Solar panel generated energy: ", amount, " kWh")
	# Add logic to handle the generated solar energy

func _on_wind_turbine_energy_generated(amount):
	print("Main: Wind turbine generated energy: ", amount, " kWh")
	# Add logic to handle the generated wind energy
func _on_human_population_resources_consumed(food, water, oxygen):
	# You can add any specific logic here if needed
	pass

func _on_human_population_waste_generated(co2, urine, feces):
	# You can add any specific logic here if needed
	pass

func _on_human_population_economic_update(net_funds):
	# You can add any specific logic here if needed
	pass







