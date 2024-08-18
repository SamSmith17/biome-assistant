extends Control

signal device_placed(device_id, position)

@export var device_list: ItemList
@export var placement_area: Control
@export var connection_status: Label
@export var error_popup: AcceptDialog

@export var ha_connector: Node
@export var ha_device_manager: Node

var dragging_device: String = ""

func _ready():
	if not ha_connector:
		ha_connector = get_node("/root/Main/HomeAssistantConnector")
	if not ha_device_manager:
		ha_device_manager = get_node("/root/Main/HADeviceManager")
	
	ha_connector.connect("connected", Callable(self, "_on_ha_connected"))
	ha_connector.connect("disconnected", Callable(self, "_on_ha_disconnected"))
	ha_connector.connect("devices_received", Callable(self, "_on_devices_received"))
	
	ha_device_manager.connect("device_added", Callable(self, "_on_device_added"))
	ha_device_manager.connect("device_removed", Callable(self, "_on_device_removed"))
	ha_device_manager.connect("device_state_changed", Callable(self, "_on_device_state_changed"))
	
	device_list.connect("item_selected", Callable(self, "_on_device_list_item_selected"))
	placement_area.connect("gui_input", Callable(self, "_on_placement_area_gui_input"))

func _on_ha_connected():
	connection_status.text = "Connected to Home Assistant"
	connection_status.modulate = Color.GREEN

func _on_ha_disconnected():
	connection_status.text = "Disconnected from Home Assistant"
	connection_status.modulate = Color.RED

func _on_devices_received(devices):
	device_list.clear()
	for device in devices.values():
		device_list.add_item(device["name"], null, true)
		device_list.set_item_metadata(device_list.get_item_count() - 1, device["id"])

func _on_device_added(device_id, godot_object):
	update_device_list()

func _on_device_removed(device_id):
	update_device_list()

func _on_device_state_changed(device_id, state):
	# Update UI to reflect state change
	# This could involve updating a label or changing the appearance of the device in the placement area
	pass

func update_device_list():
	device_list.clear()
	for device in ha_connector.devices.values():
		var is_placed = device["id"] in ha_device_manager.devices
		device_list.add_item(device["name"], null, !is_placed)
		device_list.set_item_metadata(device_list.get_item_count() - 1, device["id"])

func _on_device_list_item_selected(index):
	dragging_device = device_list.get_item_metadata(index)

func _on_placement_area_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and dragging_device:
			var device = ha_connector.devices[dragging_device]
			ha_device_manager.add_device(device)
			var godot_object = ha_device_manager.devices[dragging_device]
			godot_object.position = event.position
			emit_signal("device_placed", dragging_device, event.position)
			dragging_device = ""
			update_device_list()

func show_error(message):
	error_popup.dialog_text = message
	error_popup.popup_centered()
