extends Node

const I4_TOOLS: Array[Dictionary] = [
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
		"name": "set_eyes",
		"description": "Changes your eyes",
		"parameters": {
			"type": "object",
			"properties": {
				"eyes_name": {
					"type": "string",
					"description": "Eyes name",
					"enum": ["happy", "sad", "angry", "love"]
				},
				"is_surprised": {
					"type": ["boolean", "null"],
					"description": "Wether you are surprised or not, this toggle makes your eyes smaller, null is 'keep unchanged'",
					"default": null
				},
				"move_vertical_l": {
					"type": ["float", "null"],
					"description": "Left eye vertical position, -1 is full up, 0 is centered, 1 is full down, null is 'keep unchanged'",
					"default": null
				},
				"move_horizontal_l": {
					"type": ["float", "null"],
					"description": "Left eye horizontal position, -1 is full right, 0 is centered, 1 is full left, null is 'keep unchanged'",
					"default": null
				},
				"move_vertical_r": {
					"type": ["float", "null"],
					"description": "Right eye vertical position, -1 is full up, 0 is centered, 1 is full down, null is 'keep unchanged'",
					"default": null
				},
				"move_horizontal_r": {
					"type": ["float", "null"],
					"description": "Right eye horizontal position, -1 is full right, 0 is centered, 1 is full left, null is 'keep unchanged'",
					"default": null
				}
			},
			"required": ["eyes_name"]
		}
	}
]

@export var I4Animator: AnimationPlayer = null
@export var I4Eyes: MeshInstance3D = null
var CurrentPose: StringName = "none"

func SetPose(Name: StringName = "none") -> void:
	pass

func SetEyes(Name: StringName = "none", Surprised: Variant = null, VerticalL: Variant = null, HorizontalL: Variant = null, VerticalR: Variant = null, HorizontalR: Variant = null) -> void:
	if (Surprised != null):
		I4Eyes.set_blend_shape_value(I4Eyes.find_blend_shape_by_name("Eye_?"), int(Surprised))
	
	if (VerticalL != null):
		I4Eyes.set_blend_shape_value(I4Eyes.find_blend_shape_by_name("Eye_Down_L"), clampf(VerticalL, -1, 1))
	
	if (HorizontalL != null):
		I4Eyes.set_blend_shape_value(I4Eyes.find_blend_shape_by_name("Eye_Right_L"), clampf(HorizontalL, -1, 1))
	
	if (VerticalR != null):
		I4Eyes.set_blend_shape_value(I4Eyes.find_blend_shape_by_name("Eye_Down_R"), clampf(VerticalR, -1, 1))
	
	if (HorizontalR != null):
		I4Eyes.set_blend_shape_value(I4Eyes.find_blend_shape_by_name("Eye_Right_R"), clampf(HorizontalR, -1, 1))
