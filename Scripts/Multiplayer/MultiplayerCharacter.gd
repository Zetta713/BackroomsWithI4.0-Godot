class_name MultiplayerCharacter extends Node3D

@export_category("Name tag")
@export var NameTag: Label3D = null

@export_category("Crouch")
@export var StandingElements: Array[Node3D] = []
@export var CrouchedElements: Array[Node3D] = []

@export_category("Items")
@export var Hand: Node3D = null
var ItemInHand: Node3D = null

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
			element.process_mode = Node.NOTIFICATION_DISABLED
			element.hide()

func SetItemInHand(Item: PackedScene) -> void:
	if (ItemInHand != null):
		ItemInHand.queue_free()
	
	ItemInHand = Item.instantiate()
	ItemInHand.position = Hand.position
	Hand.add_child(ItemInHand)

func SetNameTag(Name: String) -> void:
	NameTag.text = Name
