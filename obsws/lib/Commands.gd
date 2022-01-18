extends Object

class_name Commands

var _command_id:int = 0
var _connection = null
var awaiting_response:Array = []

func _init(connection):
	_connection = connection

func execute_command(command:String, args:Dictionary) -> void:
	var packet:Dictionary = {
		"request-type": command,
		"message-id": str(_command_id),
	}
	
	for key in args.keys():
		packet[key] = args[key]
	
	awaiting_response.append({"id":_command_id, "command": command})
	_connection.get_peer(1).put_packet(JSON.print(packet).to_utf8())
	_command_id += 1

func is_waiting(id:int) -> bool:
	for waiting in awaiting_response:
		if waiting.id == id:
			return true
	return false

func waiting_command(id:int) -> String:
	for waiting in awaiting_response:
		if waiting.id == id:
			return waiting.command
	return ""

func finish_waiting(id:int) -> void:
	for waiting in awaiting_response:
		if waiting.id == id:
			awaiting_response.erase(waiting)
			return
