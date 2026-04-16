class_name MultiplayerConnection extends Node

static var VisitedLevels: Array[String] = []
static var Socket: StreamPeerTCP = StreamPeerTCP.new()

static func Connect(Host: String, Port: int) -> void:
	Disconnect()
	Socket.connect_to_host(Host, Port)

static func Disconnect() -> void:
	Socket.disconnect_from_host()

static func SendAndReceive(Action: String, Arguments: Array = []) -> Dictionary:
	Socket.put_utf8_string(JSON.stringify({"action": Action, "arguments": Arguments}))
	
	var result = Socket.get_utf8_string(-1)
	result = JSON.parse_string(result)
	
	if ("code" not in result):
		result["code"] = "OK"
	
	if ("args" not in result):
		result["args"] = []
	
	return result
