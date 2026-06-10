class_name I4CharController extends Node

const I4_TOOLS = [
	{
		"name": "set_pose",
		"description": "Changes your pose",
		"parameters": {
			"type": "object",
			"properties": {
				"pose_name": {
					"type": "string",
					"description": "Pose name",
					"enum": ["default"]
				}
			},
			"required": ["pose_name"]
		}
	},
	{
		"name": "set_mouth",
		"description": "Changes your mouth",
		"parameters": {
			"type": "object",
			"properties": {
				"mouth_name": {
					"type": "string",
					"description": "Mouth name",
					"enum": ["normal", "nervous", "cat"]
				}
			},
			"required": ["mouth_name"]
		}
	},
	{
		"name": "set_eyes",
		"description": "Changes your eyes",
		"parameters": {
			"type": "object",
			"properties": {
				"control_mode": {
					"type": "string",
					"description": "Eyes control mode",
					"enum": ["follow_player", "custom"]
				},
				"emotion": {
					"type": "string",
					"description": "Eyes emotion",
					"enum": ["happy", "sad", "angry", "love"]
				},
				"is_surprised": {
					"type": "boolean",
					"description": "Wether you are surprised or not, this toggle makes your eyes smaller, null is 'keep unchanged'",
					"default": false
				},
				"move_vertical_l": {
					"type": "float",
					"description": "Left eye vertical position, -1 is fully up, 0 is centered, 1 is fully down, null is 'keep unchanged', only works with the 'custom' control_mode",
					"default": 0
				},
				"move_horizontal_l": {
					"type": "float",
					"description": "Left eye horizontal position, -1 is fully right, 0 is centered, 1 is fully left, null is 'keep unchanged', only works with the 'custom' control_mode",
					"default": 0
				},
				"move_vertical_r": {
					"type": "float",
					"description": "Right eye vertical position, -1 is fully up, 0 is centered, 1 is fully down, null is 'keep unchanged', only works with the 'custom' control_mode",
					"default": 0
				},
				"move_horizontal_r": {
					"type": "float",
					"description": "Right eye horizontal position, -1 is fully right, 0 is centered, 1 is fully left, null is 'keep unchanged', only works with the 'custom' control_mode",
					"default": 0
				}
			},
			"required": ["control_mode", "emotion"]
		}
	}
]

@export_category("Blend shapes")
var __BS_Eyes_Happy__: int = -1
var __BS_Eyes_Sad__: int = -1
var __BS_Eyes_Angry__: int = -1
var __BS_Eyes_Love__: int = -1
var __BS_Eyes_Surprised__: int = -1
var __BS_Eyes_L_Left__: int = -1
var __BS_Eyes_L_Up__: int = -1
var __BS_Eyes_R_Left__: int = -1
var __BS_Eyes_R_Up__: int = -1
var __BS_Clothes_TShirt_Out__: int = -1
var __BS_Mouth_Nervous__: int = -1
var __BS_Mouth_Cat__: int = -1

@export_category("Animation")
@export var Animator: AnimationPlayer = null

@export_category("Eyes")
@export var Eyes: MeshInstance3D = null
@export var EyesPivot: Node3D = null
var __last_eyes_skin__: String = ""
var Eyes_Target: Node3D = null
var Eyes_Skin: String = "love"  # "happy", "sad", "angry", "love"
var Eyes_Surprised: bool = false
var Eyes_Surprised_Crazy: bool = false
var Eyes_L_OverridePosition: Vector2 = Vector2.ZERO
var Eyes_R_OverridePosition: Vector2 = Vector2.ZERO

@export_category("Body")
@export var Body: MeshInstance3D = null

@export_category("Mouth")
var Mouth_Mode: String = "normal"  # "normal", "nervous", "cat"

@export_category("Clothes")
@export var Clothes: MeshInstance3D = null
var Clothes_TShirtOut: bool = false

@export_category("Pose")
var CurrentPose: StringName = "none"

func _ready() -> void:
	__BS_Eyes_Happy__ = Eyes.find_blend_shape_by_name("Eyes_Happy")
	__BS_Eyes_Sad__ = Eyes.find_blend_shape_by_name("Eyes_Sad")
	__BS_Eyes_Angry__ = Eyes.find_blend_shape_by_name("Eyes_Angry")
	__BS_Eyes_Love__ = Eyes.find_blend_shape_by_name("Eyes_Love")
	__BS_Eyes_Surprised__ = Eyes.find_blend_shape_by_name("Eye_?")
	__BS_Eyes_L_Left__ = Eyes.find_blend_shape_by_name("Eye_Left_L")
	__BS_Eyes_L_Up__ = Eyes.find_blend_shape_by_name("Eye_Up_L")
	__BS_Eyes_R_Left__ = Eyes.find_blend_shape_by_name("Eye_Left_R")
	__BS_Eyes_R_Up__ = Eyes.find_blend_shape_by_name("Eye_Up_R")
	__BS_Clothes_TShirt_Out__ = Clothes.find_blend_shape_by_name("T-Shirt_Out")
	__BS_Mouth_Nervous__ = Body.find_blend_shape_by_name("Mouth_w")
	__BS_Mouth_Cat__ = Body.find_blend_shape_by_name("Mouth__3")
	
	Eyes_Target = get_tree().root.get_camera_3d()

func _process(Delta: float) -> void:
	# Mouth control
	Body.set_blend_shape_value(__BS_Mouth_Nervous__, 1 if (Mouth_Mode == "nervous") else 0)
	Body.set_blend_shape_value(__BS_Mouth_Cat__, 1 if (Mouth_Mode == "cat") else 0)
	
	# Clothes control
	Clothes.set_blend_shape_value(__BS_Clothes_TShirt_Out__, 1 if (Clothes_TShirtOut) else 0)
	
	# Eyes control
	var eyeLPosition = Vector2.ZERO
	var eyeRPosition = Vector2.ZERO
	
	if (Eyes_Target == null):
		# No target to look at, using override position
		eyeLPosition = Eyes_L_OverridePosition
		eyeRPosition = Eyes_R_OverridePosition
	else:
		# Look at the target
		var localDir = EyesPivot.to_local(Eyes_Target.global_position).normalized()
		
		eyeLPosition = Vector2(
			localDir.x * (1.35 if (localDir.x) < 0 else 1),
			localDir.y
		)
		eyeRPosition = Vector2(
			localDir.x * (1.35 if (localDir.x) > 0 else 1),
			localDir.y
		)
	
	if (Eyes_Surprised && Eyes_Surprised_Crazy):
		Eyes.set_blend_shape_value(__BS_Eyes_Surprised__, lerpf(Eyes.get_blend_shape_value(__BS_Eyes_Surprised__), randf_range(0, 1), Delta * 10))  # Makes the eyes smaller randomly
	else:
		Eyes.set_blend_shape_value(__BS_Eyes_Surprised__, 1 if (Eyes_Surprised) else 0)  # Makes the eyes smaller
	
	Eyes.set_blend_shape_value(__BS_Eyes_L_Left__, clampf(eyeLPosition.x, -1, 1))  # 1 = left, 0 = centered, -1 = right
	Eyes.set_blend_shape_value(__BS_Eyes_L_Up__, clampf(eyeLPosition.y, -1, 1))  # 1 = up, 0 = centered, -1 = down
	Eyes.set_blend_shape_value(__BS_Eyes_R_Left__, clampf(eyeRPosition.x, -1, 1))  # 1 = left, 0 = centered, -1 = right
	Eyes.set_blend_shape_value(__BS_Eyes_R_Up__, clampf(eyeRPosition.y, -1, 1))  # 1 = up, 0 = centered, -1 = down
	
	if (Eyes_Skin != __last_eyes_skin__):
		__last_eyes_skin__ = Eyes_Skin
		
		Eyes.set_blend_shape_value(__BS_Eyes_Happy__, 1 - int(Eyes_Skin == "happy"))  # In this case, 1 hides the eyes
		Eyes.set_blend_shape_value(__BS_Eyes_Sad__, int(Eyes_Skin == "sad"))
		Eyes.set_blend_shape_value(__BS_Eyes_Angry__, int(Eyes_Skin == "angry"))
		Eyes.set_blend_shape_value(__BS_Eyes_Love__, int(Eyes_Skin == "love"))
