extends Node

signal connected
signal disconnected
signal data_received(entity_id, state)
signal devices_received(devices)

var websocket: WebSocketPeer
@export var ha_url: String = "ws://homeassistant.local:8123/api/websocket"
@export var ha_token: String = ""

var is_connected: bool = false
var entities: Dictionary = {}
var devices: Dictionary = {}
var message_id: int = 1

func _ready():
	websocket = WebSocketPeer.new()

func connect_to_ha(url: String, token: String):
	ha_url = url
	ha_token = token
	var err = websocket.connect_to_url(ha_url)
	if err != OK:
		print("Error connecting to Home Assistant: ", err)

func _process(delta):
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		websocket.poll()
		var state = websocket.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			while websocket.get_available_packet_count():
				_on_data_received()
	elif websocket.get_ready_state() == WebSocketPeer.STATE_CLOSING:
		websocket.poll()
	elif websocket.get_ready_state() == WebSocketPeer.STATE_CLOSED:
		var code = websocket.get_close_code()
		var reason = websocket.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])
		set_process(false) # Stop processing.

func _on_data_received():
	var packet = websocket.get_packet()
	var data = packet.get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(data)
	if parse_result == OK:
		var message = json.get_data()
		handle_message(message)

func handle_message(message):
	if message.has("type"):
		match message["type"]:
			"auth_required":
				authenticate()
			"auth_ok":
				print("Authentication successful")
				is_connected = true
				emit_signal("connected")
				subscribe_to_events()
				get_devices()
			"auth_invalid":
				print("Authentication failed")
				emit_signal("disconnected")
			"event":
				if message["event"]["event_type"] == "state_changed":
					var event_data = message["event"]["data"]
					var entity_id = event_data["entity_id"]
					var new_state = event_data["new_state"]["state"]
					entities[entity_id] = new_state
					emit_signal("data_received", entity_id, new_state)
			"result":
				if message.has("id"):
					match message["id"]:
						"get_devices":
							devices = message["result"]
							emit_signal("devices_received", devices)

func authenticate():
	var auth_message = {
		"type": "auth",
		"access_token": ha_token
	}
	send_message(auth_message)

func subscribe_to_events():
	var subscribe_message = {
		"id": message_id,
		"type": "subscribe_events",
		"event_type": "state_changed"
	}
	send_message(subscribe_message)
	message_id += 1

func get_devices():
	var get_devices_message = {
		"id": "get_devices",
		"type": "config/device_registry/list"
	}
	send_message(get_devices_message)

func send_message(message: Dictionary):
	var json_string = JSON.stringify(message)
	websocket.send_string(json_string)

func get_entity_state(entity_id: String) -> String:
	return entities.get(entity_id, "unknown")

func set_entity_state(entity_id: String, service: String, data: Dictionary = {}):
	var domain = entity_id.split(".")[0]
	var service_data = data.duplicate()
	service_data["entity_id"] = entity_id
	var call_service_message = {
		"id": message_id,
		"type": "call_service",
		"domain": domain,
		"service": service,
		"service_data": service_data
	}
	send_message(call_service_message)
	message_id += 1

func turn_on_light(entity_id: String):
	set_entity_state(entity_id, "turn_on")

func turn_off_light(entity_id: String):
	set_entity_state(entity_id, "turn_off")
