extends Node

signal weather_data_loaded
signal weather_data_load_failed

@export var csv_file_path: String = "res://weather_data.csv"
@export var load_csv_button: Button
@export var csv_file_dialog: FileDialog
@export var loaded_file_label: Label

var weather_data: Array = []
var current_index: int = 0

func _ready():
	print("Weather Manager: Ready function called")
	setup()

func setup():
	print("Weather Manager: Setup function called")
	if load_csv_button:
		load_csv_button.connect("pressed", Callable(self, "_on_load_csv_button_pressed"))
	if csv_file_dialog:
		csv_file_dialog.connect("file_selected", Callable(self, "_on_csv_file_selected"))
		csv_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		csv_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		csv_file_dialog.filters = ["*.csv ; CSV Files"]
	
	load_csv_data()

func _on_load_csv_button_pressed():
	print("Weather Manager: Load CSV button pressed")
	if csv_file_dialog:
		csv_file_dialog.popup_centered()

func _on_csv_file_selected(path):
	print("Weather Manager: CSV file selected: ", path)
	csv_file_path = path
	load_csv_data()

func load_csv_data():
	print("Weather Manager: Attempting to load CSV data from: ", csv_file_path)
	weather_data.clear()
	if not FileAccess.file_exists(csv_file_path):
		print("Weather Manager: File does not exist: ", csv_file_path)
		emit_signal("weather_data_load_failed")
		return

	var file = FileAccess.open(csv_file_path, FileAccess.READ)
	if file:
		var line_count = 0
		while !file.eof_reached():
			var line = file.get_csv_line()
			line_count += 1
			if line.size() == 6:  # Updated to expect 6 columns
				var entry = {}
				var parse_success = true
				for i in range(6):
					if line[i].is_valid_float():
						entry[["temperature", "precipitation", "humidity", "windspeed", "wind_direction", "cloudcover"][i]] = float(line[i])
					else:
						print("Weather Manager: Error parsing value in line ", line_count, ": ", line[i])
						parse_success = false
						break
				if parse_success:
					weather_data.append(entry)
				else:
					print("Weather Manager: Skipping line ", line_count, " due to parsing error")
		file.close()
		print("Weather Manager: Data loaded successfully. Total entries: ", weather_data.size())
		if loaded_file_label:
			loaded_file_label.text = "Loaded file: " + csv_file_path.get_file()
		current_index = 0
		emit_signal("weather_data_loaded")
	else:
		print("Weather Manager: Failed to open file: ", csv_file_path)
		if loaded_file_label:
			loaded_file_label.text = "No file loaded"
		emit_signal("weather_data_load_failed")
func get_weather_at_index(index: int):
	if weather_data.is_empty():
		return null
	return weather_data[index % weather_data.size()]

func has_weather_data() -> bool:
	return not weather_data.is_empty()

func get_current_weather():
	if weather_data.is_empty():
		print("Weather Manager: Weather data is empty")
		return null
	return weather_data[current_index]

func advance_weather(reverse: bool = false):
	if weather_data.is_empty():
		print("Weather Manager: Cannot advance weather, data is empty")
		return
	if reverse:
		current_index = (current_index - 1 + weather_data.size()) % weather_data.size()
	else:
		current_index = (current_index + 1) % weather_data.size()

func set_current_index(index: int):
	if weather_data.is_empty():
		print("Weather Manager: Cannot set index, data is empty")
		return
	current_index = index % weather_data.size()
