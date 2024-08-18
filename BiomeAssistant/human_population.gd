extends Control

signal resources_consumed(food, water, oxygen)
signal waste_generated(co2, urine, feces)
signal economic_update(net_funds)

@export var population_size_spinbox: SpinBox
@export var food_consumption_spinbox: SpinBox
@export var water_consumption_spinbox: SpinBox
@export var oxygen_consumption_spinbox: SpinBox
@export var co2_production_spinbox: SpinBox
@export var urine_production_spinbox: SpinBox
@export var feces_production_spinbox: SpinBox
@export var daily_cost_spinbox: SpinBox
@export var daily_contribution_spinbox: SpinBox

var total_food_consumed: float = 0.0
var total_water_consumed: float = 0.0
var total_oxygen_consumed: float = 0.0
var total_co2_produced: float = 0.0
var total_urine_produced: float = 0.0
var total_feces_produced: float = 0.0
var total_net_funds: float = 0.0

func _ready():
	setup_ui()

func setup_ui():
	population_size_spinbox.value = 1
	food_consumption_spinbox.value = 2500.0  # calories per day
	water_consumption_spinbox.value = 3.0  # liters per day
	oxygen_consumption_spinbox.value = 420.0  # liters per day
	co2_production_spinbox.value = 450.0  # liters per day
	urine_production_spinbox.value = 1.5  # liters per day
	feces_production_spinbox.value = 0.2  # kg per day
	daily_cost_spinbox.value = 15.0  # USD per day
	daily_contribution_spinbox.value = 30.0  # USD per day

# ... (keep existing code)


func update_simulation(delta_time: float):
	var hours = delta_time / 3600.0  # Convert delta_time (in seconds) to hours
	
	var population = population_size_spinbox.value
	
	var food_consumed = population * (food_consumption_spinbox.value / 24.0) * hours
	var water_consumed = population * (water_consumption_spinbox.value / 24.0) * hours
	var oxygen_consumed = population * (oxygen_consumption_spinbox.value / 24.0) * hours
	
	var co2_generated = population * (co2_production_spinbox.value / 24.0) * hours
	var urine_generated = population * (urine_production_spinbox.value / 24.0) * hours
	var feces_generated = population * (feces_production_spinbox.value / 24.0) * hours
	
	total_food_consumed += food_consumed
	total_water_consumed += water_consumed
	total_oxygen_consumed += oxygen_consumed
	total_co2_produced += co2_generated
	total_urine_produced += urine_generated
	total_feces_produced += feces_generated

# Calculate economic impact
	var cost = population * (daily_cost_spinbox.value / 24.0) * hours
	var contribution = population * (daily_contribution_spinbox.value / 24.0) * hours
	var net_funds = contribution - cost
	total_net_funds += net_funds

	emit_signal("resources_consumed", food_consumed, water_consumed, oxygen_consumed)
	emit_signal("waste_generated", co2_generated, urine_generated, feces_generated)
	emit_signal("economic_update", total_net_funds)

	print("Debug: Hours passed: ", hours)
	print("Debug: Population: ", population)
	print("Debug: Hourly food consumption: ", food_consumed)
	print("Debug: Total food consumed: ", total_food_consumed)

func get_total_consumption():
	return {
		"food": total_food_consumed,
		"water": total_water_consumed,
		"oxygen": total_oxygen_consumed
	}

func get_total_waste():
	return {
		"co2": total_co2_produced,
		"urine": total_urine_produced,
		"feces": total_feces_produced
	}

func get_economic_data():
	return {
		"net_funds": total_net_funds
	}
func get_save_data():
	return {
		"population_size": population_size_spinbox.value,
		"food_consumption": food_consumption_spinbox.value,
		"water_consumption": water_consumption_spinbox.value,
		"oxygen_consumption": oxygen_consumption_spinbox.value,
		"co2_production": co2_production_spinbox.value,
		"urine_production": urine_production_spinbox.value,
		"feces_production": feces_production_spinbox.value,
		"daily_cost": daily_cost_spinbox.value,
		"daily_contribution": daily_contribution_spinbox.value,
		"total_food_consumed": total_food_consumed,
		"total_water_consumed": total_water_consumed,
		"total_oxygen_consumed": total_oxygen_consumed,
		"total_co2_produced": total_co2_produced,
		"total_urine_produced": total_urine_produced,
		"total_feces_produced": total_feces_produced,
		"total_net_funds": total_net_funds
	}

func load_save_data(data):
	population_size_spinbox.value = data["population_size"]
	food_consumption_spinbox.value = data["food_consumption"]
	water_consumption_spinbox.value = data["water_consumption"]
	oxygen_consumption_spinbox.value = data["oxygen_consumption"]
	co2_production_spinbox.value = data["co2_production"]
	urine_production_spinbox.value = data["urine_production"]
	feces_production_spinbox.value = data["feces_production"]
	daily_cost_spinbox.value = data["daily_cost"]
	daily_contribution_spinbox.value = data["daily_contribution"]
	total_food_consumed = data["total_food_consumed"]
	total_water_consumed = data["total_water_consumed"]
	total_oxygen_consumed = data["total_oxygen_consumed"]
	total_co2_produced = data["total_co2_produced"]
	total_urine_produced = data["total_urine_produced"]
	total_feces_produced = data["total_feces_produced"]
	total_net_funds = data["total_net_funds"]


func reset_totals():
	total_food_consumed = 0.0
	total_water_consumed = 0.0
	total_oxygen_consumed = 0.0
	total_co2_produced = 0.0
	total_urine_produced = 0.0
	total_feces_produced = 0.0
	total_net_funds = 0.0
	print("Debug: Totals reset")
