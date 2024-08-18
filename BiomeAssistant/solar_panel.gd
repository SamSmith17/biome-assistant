extends Node

signal energy_generated(amount)

var total_energy_generated: float = 0.0  # in kilowatt-hours

func update_energy_generation(energy_amount: float):
	# energy_amount is expected to be in kilowatt-hours
	total_energy_generated += energy_amount
	emit_signal("energy_generated", energy_amount)
	print("SolarPanel: Added %.3f kWh. New total: %.3f kWh" % [energy_amount, total_energy_generated])

func get_energy_generated() -> float:
	return total_energy_generated

func subtract_energy_generated(energy_amount: float):
	total_energy_generated = max(0, total_energy_generated - energy_amount)
	print("SolarPanel: Subtracted %.3f kWh. New total: %.3f kWh" % [energy_amount, total_energy_generated])

func reset_energy_generated():
	total_energy_generated = 0.0
	print("SolarPanel: Total energy reset to 0")
