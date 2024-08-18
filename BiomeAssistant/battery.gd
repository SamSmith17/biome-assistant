extends Node

@export var capacity = 10.0  # Capacity in kilowatt-hours
@export var max_charge_rate = 5.0  # Maximum charge rate in kilowatts
@export var max_discharge_rate = 5.0  # Maximum discharge rate in kilowatts

var current_charge = 0.0  # Current charge in kilowatt-hours

func add_charge(amount):
 var charge_amount = min(amount, max_charge_rate)
 current_charge = min(current_charge + charge_amount, capacity)

func use_charge(amount):
 var discharge_amount = min(amount, max_discharge_rate)
 current_charge = max(current_charge - discharge_amount, 0.0)

func get_charge_level():
 return current_charge / capacity

func update_charge(delta_time):
 # This function can be used to simulate self-discharge or other time-based effects
 pass
