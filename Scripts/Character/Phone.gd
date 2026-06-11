class_name Phone extends Node

@export_category("Global apps")
@export var Apps: Array[Control] = []
@export var NotCreatedApp: Control = null
var CurrentApp: Control = null

@export_category("Camera app")
@export var GUI: Control = null
signal OnCameraTakenPicture

func OpenApp(AppName: StringName) -> void:
	CloseCurrentApp()
	
	for app in Apps:
		if (app.name == AppName):
			CurrentApp = app
			
			app.show()
			app.process_mode = Node.PROCESS_MODE_INHERIT
		else:
			app.hide()
			app.process_mode = Node.PROCESS_MODE_DISABLED
	
	if (CurrentApp == null):
		CurrentApp = NotCreatedApp
		
		NotCreatedApp.show()
		NotCreatedApp.process_mode = Node.PROCESS_MODE_INHERIT

func CloseAllApps() -> void:
	OpenApp("")
	CloseCurrentApp()

func CloseCurrentApp() -> void:
	if (CurrentApp == null):
		return
	
	CurrentApp.hide()
	CurrentApp.process_mode = Node.PROCESS_MODE_DISABLED
	
	CurrentApp = null

func CameraTakePicture() -> Image:
	GUI.hide()
	var img = get_viewport().get_texture().get_image()
	GUI.show()
	
	OnCameraTakenPicture.emit(img)
	return img

func _ready() -> void:
	CloseAllApps()
