class_name CharacterMovement extends CharacterBody3D

const INTERACTION_MAX_LENGTH: float = 5
const INTERACTION_PARENT_LENGTH: int = 4
var WHISTLING_SOUNDS: Array[AudioStream] = [load("res://Audio/Whistling 1.wav")]
var INIT_SCALE_SKIN: Vector3 = Vector3.ZERO
var INIT_SCALE_COLLIDER: Vector2 = Vector2.ZERO

@export_category("Gravity")
@export var GravityMultiplier: float = 1
var FallTime: float = 0

@export_category("Speed")
const TiredSpeed: float = 3
const WalkSpeed: float = 5
const RunSpeed: float = 8
const JumpSpeed: float = 5

@export_category("Health")
var Health: float = 100

@export_category("Water")
var Water: float = 100
@export var WaterDecreaseMultiplier: float = 0.25

@export_category("Food")
var Food: float = 100
@export var FoodDecreaseMultiplier: float = 0.15

@export_category("Stamina")
var Stamina: float = 100
@export var StaminaRecover: float = 2.5
@export var TiredStaminaRecover: float = 8
@export var WalkStaminaLoss: float = 0.5
@export var RunStaminaLoss: float = 1.5
var Tired: bool = false

@export_category("Inventory")
var InventoryOpen: bool = false
var InventoryItems: Array[InventoryItem] = []

@export_category("Other")
@export var Head: Node3D = null
@export var AudioSource: AudioStreamPlayer3D = null
var MouseCaptured: bool = true
var Spawned: bool = false
var Running: bool = false
var JumpTimer: Timer = Timer.new()

func __cast_ray__(From: Vector3, Direction: Vector3, Length: float) -> CollisionObject3D:
	var hit = get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		From,
		From - Direction * Length
	))
	
	if (hit):
		return hit.collider
	
	return null

func Die() -> void:
	print("Dead")  # TODO

func Inv_FindFirstItemWithTag(Tag: String) -> InventoryItem:
	for item in InventoryItems:
		if (Tag in item.Tags):
			return item
	
	return null

func Inv_AddItem(Item: InventoryItem) -> void:
	InventoryItems.append(Item)
	
	Item.process_mode = Node.PROCESS_MODE_DISABLED
	Item.hide()
	Item.reparent(self)

func Inv_UseItem(Item: InventoryItem) -> void:
	if (Item in InventoryItems && Item.MaxUses <= 1):
		Item.MaxUses -= 1
		
		if (Item.MaxUses <= 1):
			InventoryItems.erase(Item)

func RequestInteract() -> void:
	var hit = __cast_ray__(Head.global_position, Head.global_basis.z, INTERACTION_MAX_LENGTH)
	
	if (!hit):
		return
	
	var interactibleObj = hit
	var parentIdx = 0
	
	while (interactibleObj != null && "Interact" not in interactibleObj && parentIdx <= INTERACTION_PARENT_LENGTH):
		interactibleObj = interactibleObj.get_parent_node_3d()
		parentIdx += 1
	
	if (interactibleObj != null && "Interact" in interactibleObj):
		interactibleObj.Interact()

func _ready() -> void:
	add_child(JumpTimer)
	JumpTimer.autostart = false
	JumpTimer.one_shot = true
	JumpTimer.wait_time = 0.5 * clampf(GravityMultiplier, 0.001, 9999)
	JumpTimer.start()
	
	INIT_SCALE_SKIN = $PlayerSkin.scale
	INIT_SCALE_COLLIDER = Vector2(
		$PlayerCollider.shape.radius,
		$PlayerCollider.shape.height
	)

func _input(Event: InputEvent) -> void:
	if (Event is InputEventMouseMotion && MouseCaptured):
		rotate_y(-Event.relative.x * (Globals.Sensibility * 0.01))
		Head.rotate_x(-Event.relative.y * (Globals.Sensibility * 0.01))

func _process(Delta: float) -> void:
	if (Input.is_action_just_pressed("toggle_mouse")):
		MouseCaptured = !MouseCaptured
	
	if (Input.is_action_just_pressed("act_interact") && MouseCaptured):
		RequestInteract()
	
	if (Input.is_action_just_pressed("act_whistling") && MouseCaptured && !AudioSource.playing):
		AudioSource.stream = WHISTLING_SOUNDS[randi() % WHISTLING_SOUNDS.size()]
		AudioSource.play()
	
	if (MouseCaptured):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	else:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	
	JumpTimer.wait_time = 0.5 * clampf(GravityMultiplier, 0.001, 9999)
	Water = clampf(Water - WaterDecreaseMultiplier * Delta, 0, 100)
	Food = clampf(Food - FoodDecreaseMultiplier * Delta, 0, 100)
	
	if (Water <= 0):
		Health -= WaterDecreaseMultiplier / 2 * Delta
	
	if (Food <= 0):
		Health -= FoodDecreaseMultiplier / 2 * Delta
	
	Health = clampf(Health, 0, 100)
	
	if (Health <= 0):
		Die()

func _physics_process(Delta: float) -> void:
	if (is_on_floor()):
		FallTime = 0
	else:
		velocity += get_gravity() * GravityMultiplier * (FallTime + 1) * Delta
		FallTime = clampf(FallTime + Delta, 0, clampf(GravityMultiplier, 0.001, 9999) * 9.81)
	
	if (Input.is_action_pressed("move_jump") && is_on_floor() && JumpTimer.is_stopped()):
		velocity.y = JumpSpeed
		JumpTimer.start()
	
	if (Input.is_action_pressed("toggle_crouch")):
		$PlayerSkin.scale = Vector3(INIT_SCALE_SKIN.x, INIT_SCALE_SKIN.y / 2, INIT_SCALE_SKIN.z)
		$PlayerCollider.shape.radius = INIT_SCALE_COLLIDER.x
		$PlayerCollider.shape.height = INIT_SCALE_COLLIDER.y / 2
	else:
		$PlayerSkin.scale = INIT_SCALE_SKIN
		$PlayerCollider.shape.radius = INIT_SCALE_COLLIDER.x
		$PlayerCollider.shape.height = INIT_SCALE_COLLIDER.y
	
	var speed = 0
	
	if (Input.is_action_pressed("move_sprint") and !Tired):
		speed = RunSpeed
		Running = true
	elif (!Tired):
		speed = WalkSpeed
		Running = false
	else:
		speed = TiredSpeed
		Running = false
	
	var inputDir = Input.get_vector("move_left", "move_right", "move_forward", "move_backwards") * int(MouseCaptured)
	var direction = (transform.basis * Vector3(inputDir.x, 0, inputDir.y)).normalized()
	
	if (direction):
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		
		Stamina -= (RunStaminaLoss if (Running) else WalkStaminaLoss) * Delta
	else:
		velocity.x = move_toward(velocity.x, 0, RunSpeed)
		velocity.z = move_toward(velocity.z, 0, RunSpeed)
		
		Stamina += (TiredStaminaRecover if (Tired) else StaminaRecover) * Delta
	
	Stamina = clampf(Stamina, 0, 100)
	move_and_slide()
