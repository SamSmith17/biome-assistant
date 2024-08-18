extends Node

signal device_added(device_id, godot_object)
signal device_removed(device_id)
signal device_state_changed(device_id, state)

@export var ha_connector: Node
@export var device_container: Node
@export var devices: Dictionary = {}
@export var device_data_log: Dictionary = {}

func _ready():
	if not ha_connector:
		ha_connector = get_node("root/Main/HomeAssistantConnector")
	ha_connector.connect("devices_received", Callable(self, "_on_devices_received"))
	ha_connector.connect("data_received", Callable(self, "_on_data_received"))

func _on_devices_received(ha_devices):
	for device in ha_devices:
		add_device(device)

func add_device(device):
	var device_id = device["id"]
	if device_id not in devices:
		var godot_object = create_godot_object(device)
		if godot_object:
			devices[device_id] = godot_object
			device_container.add_child(godot_object)
			emit_signal("device_added", device_id, godot_object)
			device_data_log[device_id] = []

func remove_device(device_id):
	if device_id in devices:
		var godot_object = devices[device_id]
		device_container.remove_child(godot_object)
		godot_object.queue_free()
		devices.erase(device_id)
		device_data_log.erase(device_id)
		emit_signal("device_removed", device_id)

func create_godot_object(device):
	var godot_object = null
	match device["type"]:
		"light":
			godot_object = create_light(device)
		"sensor":
			godot_object = create_sensor(device)
		# Add more device types here as needed
	return godot_object

func create_light(device):
	var light = OmniLight3D.new()
	light.name = device["name"]
	light.light_energy = 0.0
	
	var entity_id = get_entity_id_for_device(device)
	if entity_id:
		light.set_meta("entity_id", entity_id)
		light.connect("visibility_changed", Callable(self, "_on_light_visibility_changed").bind(light))
	
	return light

func create_sensor(device):
	var sensor = Label3D.new()
	sensor.name = device["name"]
	
	var entity_id = get_entity_id_for_device(device)
	if entity_id:
		sensor.set_meta("entity_id", entity_id)
	
	return sensor

func get_entity_id_for_device(device):
	return device["type"] + "." + device["name"].to_lower().replace(" ", "_")

func _on_data_received(entity_id, state):
	for device_id in devices:
		var device = devices[device_id]
		if device.get_meta("entity_id") == entity_id:
			update_device_state(device_id, device, state)

func update_device_state(device_id, device, state):
	if device is OmniLight3D:
		device.light_energy = 1.0 if state == "on" else 0.0
	elif device is Label3D:
		device.text = device.name + ": " + state
	
	log_device_state(device_id, state)
	emit_signal("device_state_changed", device_id, state)

func _on_light_visibility_changed(light):
	var entity_id = light.get_meta("entity_id")
	if light.light_energy > 0:
		ha_connector.turn_on_light(entity_id)
	else:
		ha_connector.turn_off_light(entity_id)

func log_device_state(device_id, state):
	var timestamp = Time.get_unix_time_from_system()
	device_data_log[device_id].append({"timestamp": timestamp, "state": state})

func get_device_log(device_id):
	return device_data_log.get(device_id, [])

func clear_device_log(device_id):
	if device_id in device_data_log:
		device_data_log[device_id].clear()

func save_device_logs():
	var file = FileAccess.open("user://device_logs.json", FileAccess.WRITE)
	file.store_line(JSON.stringify(device_data_log))
	file.close()

func load_device_logs():
	if FileAccess.file_exists("user://device_logs.json"):
		var file = FileAccess.open("user://device_logs.json", FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			device_data_log = json.get_data()
