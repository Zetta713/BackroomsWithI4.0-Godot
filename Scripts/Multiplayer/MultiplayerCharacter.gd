class_name MultiplayerCharacter extends Node3D

@export_category("Name tag")
@export var NameTag: Label3D = null

@export_category("Crouch")
@export var StandingElements: Array[Node3D] = []
@export var CrouchedElements: Array[Node3D] = []

@export_category("Items")
@export var Hand: Node3D = null
var ItemInHand: Node3D = null

@export_category("Movement")
var IsMoving: bool = false
var LastPosition: Vector3 = Vector3.ZERO

@export_category("Sound")
var Sounds: Dictionary[String, AudioStreamPlayer3D] = {}

func SetCrouched(Value: bool) -> void:
	for element in StandingElements:
		if (element is CollisionShape3D):
			element.disabled = Value
		
		if (Value):
			element.process_mode = Node.PROCESS_MODE_DISABLED
			element.hide()
		else:
			element.process_mode = Node.PROCESS_MODE_INHERIT
			element.show()
	
	for element in CrouchedElements:
		if (element is CollisionShape3D):
			element.disabled = !Value
		
		if (Value):
			element.process_mode = Node.PROCESS_MODE_INHERIT
			element.show()
		else:
			element.process_mode = Node.PROCESS_MODE_DISABLED
			element.hide()

func SetItemInHand(Item: PackedScene) -> void:
	if (ItemInHand != null):
		ItemInHand.queue_free()
	
	ItemInHand = Item.instantiate()
	ItemInHand.position = Hand.position
	Hand.add_child(ItemInHand)

func SetNameTag(Name: String) -> void:
	NameTag.text = Name

func PlaySound(Type: String, Sound: AudioStream) -> void:
	if (Type not in Sounds):
		Sounds[Type] = null
	
	if (Sounds[Type] == null):
		var player = AudioStreamPlayer3D.new()
		player.autoplay = false
		player.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_PHYSICS_STEP
		add_child(player)
		
		Sounds[Type] = player
	
	if (Sounds[Type].playing):
		return
	
	Sounds[Type].stream = Sound
	Sounds[Type].play()

func UpdateParameters() -> void:
	IsMoving = global_position != LastPosition
	LastPosition = global_position
