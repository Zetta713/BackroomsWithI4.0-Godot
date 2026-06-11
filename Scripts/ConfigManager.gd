extends Node

@export var GUI_Elements: Dictionary[String, Control] = {
	"ViewDistance": null,
	"Sensibility": null,
	"GenerationTime": null,
	"Multiplayer_Host": null,
	"Multiplayer_Port": null,
	"Multiplayer_UpdateTime": null,
	"User_Username": null,
	"User_Password": null
}

func _ready() -> void:
	Globals.CheckInstance()
	
	for paramName in GUI_Elements.keys():
		var elementNode = GUI_Elements[paramName]
		
		if (elementNode == null || paramName not in Globals.Instance):
			continue
		
		if ("value" in elementNode):
			elementNode.set("value", Globals.Instance.get(paramName))
		elif ("text" in elementNode):
			elementNode.set("text", Globals.Instance.get(paramName))
		else:
			continue

func _process(_Delta: float) -> void:
	for paramName in GUI_Elements.keys():
		var elementNode = GUI_Elements[paramName]
		var paramValue = null
		
		if (elementNode == null || paramName not in Globals.Instance):
			continue
		
		if ("value" in elementNode):
			paramValue = elementNode.value
		elif ("text" in elementNode):
			paramValue = elementNode.text
		else:
			continue
		
		Globals.Instance.set(paramName, paramValue)

func Save() -> void:
	Globals.Instance.SaveConfig()
