extends Node

func _ready() -> void:
	if (Globals.LevelToLoad == null || len(Globals.LevelToLoad.strip_edges()) == 0):
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	else:
		ResourceLoader.load_threaded_request(Globals.LevelToLoad)

func _process(_Delta: float) -> void:
	var state = ResourceLoader.load_threaded_get_status(Globals.LevelToLoad)
	
	match state:
		ResourceLoader.THREAD_LOAD_LOADED:
			var scene = ResourceLoader.load_threaded_get(Globals.LevelToLoad)
			get_tree().change_scene_to_packed.call_deferred(scene)
