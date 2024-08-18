extends Node

signal energy_generated(amount)

@export var height: float = 0.45 # meters
@export var radius: float = 0.1 # meters
@export var efficiency: float = 0.4 # 40% efficiency
@export var cut_in_speed: float = 3.0 # m/s

var total_energy_generated: float = 0.0 # in kilowatt-hours

const AIR_DENSITY: float = 1.225 # kg/m³

func calculate_sweep_area() -> float:
	return height * 2 * radius

func calculate_wind_power(wind_speed: float) -> float:
	var sweep_area = calculate_sweep_area()
	return 0.5 * AIR_DENSITY * pow(wind_speed, 3) * sweep_area

func update_energy_generation(wind_speed: float, delta_time: float):
	var power_output = calculate_wind_power(wind_speed)
	var adjusted_power_output = power_output * efficiency
	
	if wind_speed < cut_in_speed:
		adjusted_power_output = 0
	
	var energy_generated = (adjusted_power_output / 1000.0) * (delta_time / 3600.0)
	
	total_energy_generated += energy_generated
	emit_signal("energy_generated", energy_generated)

func get_total_energy_generated() -> float:
	return total_energy_generated

func get_energy_generated() -> float:
	return total_energy_generated

func set_total_energy_generated(value: float):
	total_energy_generated = value

func reset_energy_generated():
	total_energy_generated = 0.0
