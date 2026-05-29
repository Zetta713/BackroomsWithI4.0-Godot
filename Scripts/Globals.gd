class_name Globals extends Resource

static var Instance: Globals = null

# ====================
#       GRAPHICS
# ====================

var ViewDistance: int = 50
var Sensibility: float = 3
var GenerationTime: float = 2

# ====================
#     MULTIPLAYER
# ====================

var Multiplayer_Host: String = "main.tao71.org"
var Multiplayer_Port: int = 65287
var Multiplayer_UpdateTime: float = 0

# ====================
#       ACCOUNT
# ====================

var User_Username: String = "Player"
var User_Password: String = ""

# ====================
#       SOUND ID
# ====================

enum SoundID
{
	NO_SOUND = -1,
	WHISTLE_1 = 0,
	WHISTLE_2 = 1
}

static func ParseSound(ID: SoundID) -> Array:
	if (ID == SoundID.WHISTLE_1):
		return ["Whistle", load("res://Audio/Whistling 1.wav")]
	elif (ID == SoundID.WHISTLE_2):
		return ["Whistle", load("res://Audio/Whistling 2.wav")]
	
	return ["", null]

static func CreateSoundPlayers(Self: bool, Parent: Node3D) -> Dictionary[String, AudioStreamPlayer3D]:
	var whistlePlayer = AudioStreamPlayer3D.new()
	whistlePlayer.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	whistlePlayer.unit_size = 25
	whistlePlayer.max_distance = 400
	whistlePlayer.autoplay = false
	whistlePlayer.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	Parent.add_child(whistlePlayer)
	
	return {
		"Whistle": whistlePlayer
	}

static func GetGameConfigDirPath() -> String:
	var d = OS.get_data_dir() + "/BackroomsWithI4.0"
	
	if (!DirAccess.dir_exists_absolute(d)):
		DirAccess.make_dir_recursive_absolute(d)
	
	return d

static func ParsePath(Path: String) -> String:
	var path = Path.strip_edges()
	path = path.replace("[$GAME_CONFIG_DIR]", GetGameConfigDirPath())
	
	return path

static func __load_config_parser__(Ins: Variant, D: Dictionary) -> void:
	for paramName in D.keys():
		var paramValue = D[paramName]
		
		if (typeof(paramValue) == TYPE_DICTIONARY):
			if (paramName in Ins):
				__load_config_parser__(Ins.get(paramName), paramValue)
			else:
				Ins.set(paramName, paramValue)
		else:
			Ins.set(paramName, paramValue)

static func LoadConfig(ConfigPath: String = "[$GAME_CONFIG]/config.json", SetGlobal: bool = true) -> Globals:
	var parsedPath = ParsePath(ConfigPath)
	var instance = Globals.new()
	
	if (SetGlobal):
		Instance = instance
	
	if (!FileAccess.file_exists(parsedPath)):
		push_warning("Config does not exist. Creating.")
		instance.SaveConfig(ConfigPath)
		
		return instance
	
	var file = FileAccess.open(parsedPath, FileAccess.READ)
	
	if (file == null):
		push_error("Could not open config file. Returning default config.")
		return instance
	
	var json = file.get_as_text()
	file.close()
	
	json = JSON.parse_string(json)
	__load_config_parser__(instance, json)
	
	return instance

func __save_config_parser__(Properties: Dictionary, Obj: Object = null) -> Dictionary:
	var ctx = self if (Obj == null) else Obj
	var json = {}
	
	for propName in Properties.keys():
		var propValue = ctx.get(propName)
		
		if (propValue is Node || (propValue is Object && propValue is not Resource)):
			continue
		
		if (typeof(propValue) == TYPE_OBJECT && propValue.has_method("get_property_list")):
			var subProps = {}
			
			for p in propValue.get_property_list():
				if ((p["usage"] & PROPERTY_USAGE_STORAGE) && !p["name"].begins_with("_")):
					subProps[p["name"]] = true
			
			json[propName] = __save_config_parser__(subProps, propValue)
		else:
			json[propName] = propValue
	
	return json

func SaveConfig(ConfigPath: String = "[$GAME_CONFIG]/config.json") -> Dictionary[String, Variant]:
	var parsedPath = ParsePath(ConfigPath)
	var properties = get_property_list()
	var json = {}
	
	for prop in properties:
		var propName = prop["name"]
		var propValue = get(propName)
		
		json[propName] = propValue
	
	json = __save_config_parser__(json)
	var file = FileAccess.open(parsedPath, FileAccess.WRITE)
	
	if (file == null):
		push_error("Could not open config file. Could not save config.")
		return properties
	
	file.store_string(JSON.stringify(json))
	file.close()
	
	return json
