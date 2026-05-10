class_name Globals extends Node

# ====================
#        DEBUG
# ====================

const Multiplayer_Debug: bool = true
const Multiplayer_Debug_Users: Dictionary[String, String] = {
	"test1": "test1",
	"test2": "test2",
	"test3": "test3",
	"test4": "test4",
	"test5": "test5",
	"test6": "test6"
}

# ====================
#       GRAPHICS
# ====================

static var ViewDistance: int = 50
static var Sensibility: float = 3
static var GenerationTime: float = 2

# ====================
#     MULTIPLAYER
# ====================

static var Multiplayer_Server: String = "ws://127.0.0.1:65287"
static var Multiplayer_UpdateTime: float = 0

# ====================
#       ACCOUNT
# ====================

static var User_Username: String = "Player"
static var User_Password: String = ""

# ====================
#       SOUND ID
# ====================

enum SoundID
{
	NO_SOUND = -1,
	WHISTLE_1 = 0
}

static func ParseSound(ID: SoundID) -> Array:
	if (ID == SoundID.WHISTLE_1):
		return ["Whistle", load("res://Audio/Whistling 1.wav")]
	
	return ["", null]

static func CreateSoundPlayers(Self: bool, Parent: Node3D) -> Dictionary[String, AudioStreamPlayer3D]:
	var whistlePlayer = AudioStreamPlayer3D.new()
	whistlePlayer.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	whistlePlayer.unit_size = 25
	whistlePlayer.max_distance = 750
	whistlePlayer.autoplay = false
	whistlePlayer.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
	Parent.add_child(whistlePlayer)
	
	return {
		"Whistle": whistlePlayer
	}
