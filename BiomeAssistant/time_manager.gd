extends Node

var current_index: int = 0
var years_elapsed: int = 0
var start_year: int = 2024
var time_scale: float = 1.0

func _ready():
	pass  # Add any initialization code here if needed

func setup():
	pass  # Add any setup code here if needed

func set_time_scale(value: float):
	time_scale = value

func get_time_scale() -> float:
	return time_scale

func set_current_index(index: int):
	current_index = index % 8760  # Ensure we wrap around at the end of the year
	years_elapsed = index / 8760  # Update years elapsed

func get_current_index() -> int:
	return current_index

func advance_time(hours: float):
	var total_hours = int(current_index + hours)
	years_elapsed += total_hours / 8760
	current_index = total_hours % 8760
	print("TimeManager: Advanced time by %.2f hours. New index: %d, Years elapsed: %d" % [hours, current_index, years_elapsed])

func get_current_date_time() -> Dictionary:
	var day_of_year = current_index / 24 + 1
	var hour = current_index % 24
	var month = 1
	var day = day_of_year
	var month_lengths = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	
	for length in month_lengths:
		if day <= length:
			break
		day -= length
		month += 1
	
	return {
		"year": start_year + years_elapsed,
		"month": month,
		"day": day,
		"hour": hour,
		"years_elapsed": years_elapsed
	}

func get_day_of_year() -> int:
	return current_index / 24 + 1

func get_hour() -> int:
	return current_index % 24
