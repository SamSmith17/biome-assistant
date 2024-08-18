extends Node

signal play_pressed
signal pause_pressed
signal reverse_pressed
signal timescale_changed(value)
signal timeline_changed(value)
signal device_placed(device_id, position)

# UI references
@export var temperature_label: Label
@export var precipitation_label: Label
@export var humidity_label: Label
@export var windspeed_label: Label
@export var wind_direction_label: Label
@export var date_label: Label
@export var hour_label: Label
@export var year_label: Label
@export var years_elapsed_label: Label
@export var result_label: Label
@export var total_rain_label: Label
@export var total_solar_label: Label
@export var total_wind_energy_label: Label
@export var play_button: Button
@export var pause_button: Button
@export var reverse_button: Button
@export var timescale_slider: HSlider
@export var timeline_slider: HSlider

# Human Population UI
@export var food_consumed_label: Label
@export var water_consumed_label: Label
@export var oxygen_consumed_label: Label
@export var co2_produced_label: Label
@export var urine_produced_label: Label
@export var feces_produced_label: Label
@export var budget_label: Label

# Configuration nodes
@export var longitude_spinbox: SpinBox
@export var latitude_spinbox: SpinBox
@export var orientation_spinbox: SpinBox
@export var tilt_spinbox: SpinBox
@export var efficiency_spinbox: SpinBox
@export var array_area_spinbox: SpinBox
@export var ambient_temp_spinbox: SpinBox
@export var temp_coefficient_spinbox: SpinBox
@export var rated_kw_spinbox: SpinBox
@export var rain_area_spinbox: SpinBox

# Home Assistant UI elements
@export var device_list: ItemList
@export var placement_area: Control
@export var connection_status: Label
@export var error_popup: AcceptDialog

var total_rain: float = 0.0
var total_solar: float = 0.0
var total_wind_energy: float = 0.0

func _ready():
	print("UIManager: _ready called")

func setup():
	print("UIManager: setup called")
	connect_signals()
	setup_ui_controls()

func connect_signals():
	print("UIManager: Connecting signals")
	play_button.connect("pressed", Callable(self, "_on_play_button_pressed"))
	pause_button.connect("pressed", Callable(self, "_on_pause_button_pressed"))
	reverse_button.connect("pressed", Callable(self, "_on_reverse_button_pressed"))
	timescale_slider.connect("value_changed", Callable(self, "_on_timescale_slider_changed"))
	timeline_slider.connect("value_changed", Callable(self, "_on_timeline_slider_changed"))
	device_list.connect("item_selected", Callable(self, "_on_device_list_item_selected"))
	placement_area.connect("gui_input", Callable(self, "_on_placement_area_gui_input"))

func setup_ui_controls():
	print("UIManager: Setting up UI controls")
	timescale_slider.min_value = -1000
	timescale_slider.max_value = 1000
	timescale_slider.step = 1
	timescale_slider.value = 1
	
	timeline_slider.min_value = 0
	timeline_slider.max_value = 8759
	timeline_slider.step = 1
	timeline_slider.value = 0
	
	# Setup other UI controls (spinboxes, etc.)
	# ...

func _on_play_button_pressed():
	print("UIManager: Play button pressed")
	emit_signal("play_pressed")

func _on_pause_button_pressed():
	print("UIManager: Pause button pressed")
	emit_signal("pause_pressed")

func _on_reverse_button_pressed():
	print("UIManager: Reverse button pressed")
	emit_signal("reverse_pressed")

func _on_timescale_slider_changed(value):
	print("UIManager: Timescale changed to ", value)
	emit_signal("timescale_changed", value)

func _on_timeline_slider_changed(value):
	print("UIManager: Timeline changed to ", value)
	emit_signal("timeline_changed", value)

func update_weather_display(weather_data):
	print("UIManager: Updating weather display")
	temperature_label.text = "Temperature: %.1f°C" % weather_data["temperature"]
	precipitation_label.text = "Precipitation: %.1f mm" % weather_data["precipitation"]
	humidity_label.text = "Humidity: %.1f%%" % weather_data["humidity"]
	windspeed_label.text = "Wind Speed: %.1f m/s" % weather_data["windspeed"]
	wind_direction_label.text = "Wind Direction: %.1f°" % weather_data["wind_direction"]

func update_date_time(date_time: Dictionary):
	print("UIManager: Updating date and time")
	date_label.text = "Date: %02d/%02d/%d" % [date_time["month"], date_time["day"], date_time["year"]]
	hour_label.text = "Hour: %02d:00" % date_time["hour"]
	year_label.text = "Current Year: %d" % date_time["year"]
	years_elapsed_label.text = "Years Elapsed: %d" % date_time["years_elapsed"]

func update_solar_output(output: float):
	print("UIManager: Updating solar output display: %.3f Wh" % output)
	if result_label:
		result_label.text = "Hourly Solar Output: %.1f Wh" % output
	else:
		print("UIManager: result_label is null")

func update_wind_output(output: float):
	print("UIManager: Updating wind output display: %.3f kWh" % output)
	total_wind_energy = output
	if total_wind_energy_label:
		total_wind_energy_label.text = "Total Wind Energy: %.2f kWh" % output
	else:
		print("UIManager: total_wind_energy_label is null")

func update_human_population(consumption: Dictionary, waste: Dictionary, economic_data: Dictionary):
	print("UIManager: Updating human population display")
	if food_consumed_label:
		food_consumed_label.text = "Food Consumed: %.2f cal" % consumption["food"]
	if water_consumed_label:
		water_consumed_label.text = "Water Consumed: %.2f L" % consumption["water"]
	if oxygen_consumed_label:
		oxygen_consumed_label.text = "Oxygen Consumed: %.2f L" % consumption["oxygen"]
	if co2_produced_label:
		co2_produced_label.text = "CO2 Produced: %.2f L" % waste["co2"]
	if urine_produced_label:
		urine_produced_label.text = "Urine Produced: %.2f L" % waste["urine"]
	if feces_produced_label:
		feces_produced_label.text = "Feces Produced: %.2f kg" % waste["feces"]
	if budget_label:
		budget_label.text = "Budget: $%.2f" % economic_data["net_funds"]

func get_solar_parameters() -> Dictionary:
	return {
		"latitude": latitude_spinbox.value if latitude_spinbox else 0,
		"longitude": longitude_spinbox.value if longitude_spinbox else 0,
		"orientation": orientation_spinbox.value if orientation_spinbox else 0,
		"tilt": tilt_spinbox.value if tilt_spinbox else 0,
		"efficiency": efficiency_spinbox.value if efficiency_spinbox else 0,
		"array_area": array_area_spinbox.value if array_area_spinbox else 0,
		"ambient_temp": ambient_temp_spinbox.value if ambient_temp_spinbox else 25,
		"temp_coefficient": temp_coefficient_spinbox.value if temp_coefficient_spinbox else 0,
		"rated_kw": rated_kw_spinbox.value if rated_kw_spinbox else 1,
	}

func update_totals(precipitation: float, rain_area: float, solar_energy: float, wind_energy: float):
	print("UIManager: Updating totals display")
	total_rain += precipitation * rain_area
	total_solar = solar_energy  # Use the provided solar_energy value
	total_wind_energy = wind_energy

	if total_rain_label:
		total_rain_label.text = "Total Rain: %.1f L" % total_rain
	if total_solar_label:
		total_solar_label.text = "Total Solar: %.3f kWh" % total_solar
	if total_wind_energy_label:
		total_wind_energy_label.text = "Total Wind Energy: %.3f kWh" % total_wind_energy

	print("UIManager: Updated total solar display: %.3f kWh" % total_solar)
	print("UIManager: Updated total wind display: %.3f kWh" % total_wind_energy)
	print("UIManager: Updated total rain display: %.1f L" % total_rain)

func get_rain_area() -> float:
	return rain_area_spinbox.value if rain_area_spinbox else 1.0

func update_device_list(devices, placed_devices):
	print("UIManager: Updating device list")
	if not device_list:
		print("UIManager: Device list not assigned")
		return
	
	device_list.clear()
	if devices.is_empty():
		print("UIManager: No devices available")
		return
	
	for device in devices.values():
		var is_placed = placed_devices.has(device["id"]) if placed_devices else false
		device_list.add_item(device["name"], null, !is_placed)
		device_list.set_item_metadata(device_list.get_item_count() - 1, device["id"])

func _on_device_list_item_selected(index):
	var device_id = device_list.get_item_metadata(index)
	print("UIManager: Device selected: ", device_id)

func _on_placement_area_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var device_id = device_list.get_item_metadata(device_list.get_selected_items()[0])
		print("UIManager: Device placed: ", device_id, " at position: ", event.position)
		emit_signal("device_placed", device_id, event.position)

func show_error(message):
	print("UIManager: Showing error: ", message)
	if error_popup:
		error_popup.dialog_text = message
		error_popup.popup_centered()
	else:
		print("UIManager: Error popup not assigned. Error message: ", message)

func update_connection_status(connected: bool):
	print("UIManager: Updating connection status: ", connected)
	if connection_status:
		if connected:
			connection_status.text = "Connected to Home Assistant"
			connection_status.modulate = Color.GREEN
		else:
			connection_status.text = "Disconnected from Home Assistant"
			connection_status.modulate = Color.RED
	else:
		print("UIManager: Connection status label not assigned")

func update_play_button_state(is_playing: bool):
	print("UIManager: Updating play button state: ", is_playing)
	if play_button and pause_button:
		play_button.disabled = is_playing
		pause_button.disabled = !is_playing
	else:
		print("UIManager: Play or Pause button not assigned")

func update_timeline(value: int):
	print("UIManager: Updating timeline to: ", value)
	if timeline_slider:
		timeline_slider.value = value
	else:
		print("UIManager: Timeline slider not assigned")
