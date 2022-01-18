extends Node

class_name ObsWs

signal obs_connected()
signal obs_disconnected()
signal obs_event(event, data)
signal obs_response(command, data)
signal obs_error(data)

export var host:String = "localhost"
export var port:String = "4444"
export var password:String = ""

const POLL_TIME: float = 1.0
var _poll_counter: float = 0.0

var _client:WebSocketClient = null

var _commands:Commands = null

func _process(delta: float) -> void:
	if _client == null:
		return
	_poll_counter += delta
	if _poll_counter >= POLL_TIME:
		_poll_counter = 0.0
		if _client.get_connection_status() != WebSocketClient.CONNECTION_DISCONNECTED:
			_client.poll()

func connect_to_host() -> bool:
	_client = WebSocketClient.new()
	_client.verify_ssl = false
	_commands = Commands.new(_client)
	_client.connect("connection_closed", self, "_on_connection_closed")
	_client.connect("connection_error", self, "_on_connection_error")
	_client.connect("connection_established", self, "_on_connection_established")
	_client.connect("data_received", self, "_on_data_received")
	_client.connect("server_close_request", self, "_on_server_close_request")
	if _client.connect_to_url("ws://%s:%s" % [host, port]) == OK:
		return true
	return false

func command(command:String, args:Dictionary):
	_commands.execute_command(command, args)

# Events
func _on_connection_closed(_was_clean_close: bool):
	pass

func _on_connection_error():
	var json_response : Dictionary = {"error":"Connection Error.", "message-id":"-2", "status":"error"}
	emit_signal("obs_error", fix_names(json_response))

func _on_connection_established(_protocol: String):
	_client.get_peer(1).set_write_mode(WebSocketPeer.WRITE_MODE_TEXT)
	_commands.execute_command("GetAuthRequired", {})

func fix_names(packet:Dictionary) -> Dictionary:
	var replace:Dictionary = {}
	for key in packet.keys():
		if "-" in key:
			var nkey = key.replace("-","_")
			replace[key] = nkey
	
	for key in replace.keys():
		if typeof(packet[key]) == TYPE_DICTIONARY:
			packet[replace[key]] = fix_names(packet[key])
			packet.erase(key)
		else:
			packet[replace[key]] = packet[key]
			packet.erase(key)
	return packet

func _on_data_received():
	var message: String = _client.get_peer(1).get_packet().get_string_from_utf8().strip_edges().strip_escapes()
	
	var packet = parse_json(message)
	if typeof(packet) != TYPE_DICTIONARY:
		var response:Dictionary = {"error": "Data Packet Error", "message-id": "-1", "status": "Packet received was not a JSON Object!"}
		emit_signal("obs_error", fix_names(response))
		return
	
	packet = fix_names(packet)
	
	if packet.has("error"):
		if packet.has("message_id"):
			_commands.finish_waiting(packet.message_id)
		printerr("Error: %s", packet.error)
		emit_signal("obs_error", packet)
		return
	
	# Handle Packet
	if packet.has("update_type"):  # Event from OBS
		var event = packet.update_type
		packet.erase("update_type")
		emit_signal("obs_event", event, packet)
		
	elif packet.has("message_id"): # Response from OBS
		packet.id = int(packet.message_id)
		packet.erase("message_id")
		if _commands.is_waiting(packet.id):
			if _commands.waiting_command(packet.id) == "GetAuthRequired":
				_commands.finish_waiting(packet.id)
				if packet.authRequired:
					var secret_combined: String = "%s%s" % [password, packet.salt]
					var secret_base64 = Marshalls.raw_to_base64(secret_combined.sha256_buffer())
					var auth_combined: String = "%s%s" % [secret_base64, packet.challenge]
					var auth_base64: String = Marshalls.raw_to_base64(auth_combined.sha256_buffer())
					_commands.execute_command("Authenticate",{"auth": auth_base64})
					return
				else:
					emit_signal("obs_connected")
					return
			
			if _commands.waiting_command(packet.id) == "Authenticate":
				if packet.status == "ok":
					emit_signal("obs_connected")
					return
			
			emit_signal("obs_response", _commands.waiting_command(packet.id), packet)
			_commands.finish_waiting(packet.id)
		else:
			printerr("Receieved unhandled message from OBS: %s" % JSON.print(message, "\t"))

func _on_server_close_request(_code: int, _reason: String):
	_client.disconnect_from_host()
