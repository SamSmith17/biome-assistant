extends Node

signal energy_generated(amount)

var total_energy_generated = 0.0  # in kilowatt-hours

func update_energy_generation(energy_amount, delta_time):
	# energy_amount is in kilowatt-hours
	total_energy_generated += energy_amount
	emit_signal("energy_generated", energy_amount)

func get_energy_generated():
	return total_energy_generated

func get_total_energy_generated():
	return total_energy_generated

func set_total_energy_generated(value):
	total_energy_generated = value
