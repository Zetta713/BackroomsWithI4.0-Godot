class_name WorldGen extends Node3D

@export_category("Chunk options")
@export var DisabledChunkPositions: Array[WorldGen_DisabledChunkPosition] = []
@export var ChunkSize: Vector3i = Vector3i.ONE
@export var Chunks: Array[PackedScene] = []
@export var GenerateX: bool = true
@export var GenerateZ: bool = true
var ChunkPool: Array[Node3D] = []
var LoadedChunks: Dictionary[Vector3i, Node3D] = {}
var InstancedChunkParent: Node3D = null
var ClonedChunkParent: Node3D = null

@export_category("Map options")
@export var LevelName: String = ""
@export var Maps: Array[Texture2D] = []
@export var BlackTextureInsteadOfNoise: bool = false
var LoadedMaps: Dictionary[int, Texture2D] = {}
@export var MultipleFloors: bool = true

@export_category("Player options")
@export var Player: CharacterMovement = null
@export var PlayerSpawnMin: Vector3i = Vector3i.ZERO
@export var PlayerSpawnMax: Vector3i = Vector3i(1000, 10, 1000)
@export var PlayerSpawnOffset: Vector3 = Vector3.ZERO
@export var PlayerSpawnFullRandom: bool = true
var PlayerSpawns: Array[Vector3] = []
@export var PlayerDieFalling: bool = false
@export var PlayerDieFallingDistance: float = 100

@export_category("Other options")
@export var Multiplayer: bool = true
var Generate: bool = false
var GenerationCompleted: bool = true
var RNG: RandomNumberGenerator = RandomNumberGenerator.new()
var FNL: FastNoiseLite = FastNoiseLite.new()

func SetSeed(Seed: int) -> void:
	RNG.seed = Seed
	FNL.seed = Seed

func GetChunkIndex(NoiseBrightness: float) -> int:
	return int(round(NoiseBrightness * (ChunkPool.size() - 1)))

func GetPixelInImage(
	Img: Image,
	WorldPos: Vector2i,
	FloorSize: Vector2i
) -> Color:
	var texturePixelPos = Vector2i(
		int(WorldPos.x) % FloorSize.x,
		int(WorldPos.y) % FloorSize.y
	)
	
	if (texturePixelPos.x < 0): texturePixelPos.x += FloorSize.x
	if (texturePixelPos.y < 0): texturePixelPos.y += FloorSize.y
	
	return Img.get_pixel(texturePixelPos.x, texturePixelPos.y)

func UpdateChunks() -> void:
	if (!Generate && !GenerationCompleted):
		return
	
	GenerationCompleted = false
	
	var currentChunk = Vector3i(
		roundi(Player.global_position.x / ChunkSize.x),
		roundi(Player.global_position.y / ChunkSize.y),
		roundi(Player.global_position.z / ChunkSize.z)
	)
	var floors = []
	var genX = []
	var genZ = []
	
	if (MultipleFloors):
		floors = [-1, 0, 1]
	else:
		floors = [0]
	
	if (GenerateX):
		genX = range(-Globals.ViewDistance / 2, Globals.ViewDistance / 2 + 1)
	else:
		genX = [0]
	
	if (GenerateZ):
		genZ = range(-Globals.ViewDistance / 2, Globals.ViewDistance / 2 + 1)
	else:
		genZ = [0]
	
	for y in floors:
		var floorTexture: Texture2D = null
		var floorImage: Image = null
		
		if (Maps.size() > 0):
			if (currentChunk.y + y in LoadedMaps.keys()):
				floorTexture = LoadedMaps[currentChunk.y + y]
			else:
				floorTexture = Maps[RNG.randi_range(0, Maps.size() - 1)]
				LoadedMaps[currentChunk.y + y] = floorTexture
			
			floorImage = floorTexture.get_image()
		else:
			floorImage = FNL.get_image(ChunkSize.x * 100, ChunkSize.z * 100)
			floorTexture = ImageTexture.create_from_image(floorImage)
			
			Maps.append(floorTexture)
		
		var floorSize = Vector2i(floorTexture.get_width(), floorTexture.get_height())
		
		for x in genX:
			for z in genZ:
				var coords = Vector3i(
					currentChunk.x + x,
					currentChunk.y + y,
					currentChunk.z + z
				)
				var inDisabledChunk = false
				
				for disabledChunk in DisabledChunkPositions:
					if (
						(coords.x >= disabledChunk.MinPosition.x && coords.x <= disabledChunk.MaxPosition.x) &&
						(coords.y >= disabledChunk.MinPosition.y && coords.y <= disabledChunk.MaxPosition.y) &&
						(coords.z >= disabledChunk.MinPosition.z && coords.z <= disabledChunk.MaxPosition.z)
					):
						inDisabledChunk = true
						break
				
				if (coords in LoadedChunks || inDisabledChunk):
					continue
				
				var pixelCurrent = GetPixelInImage(
					floorImage,
					Vector2i(coords.x * ChunkSize.x, coords.z * ChunkSize.z),
					floorSize
				)
				var pixelLeft = GetPixelInImage(
					floorImage,
					Vector2i((coords.x + 1) * ChunkSize.x, coords.z * ChunkSize.z),
					floorSize
				)
				var pixelRight = GetPixelInImage(
					floorImage,
					Vector2i((coords.x - 1) * ChunkSize.x, coords.z * ChunkSize.z),
					floorSize
				)
				var pixelBack = GetPixelInImage(
					floorImage,
					Vector2i(coords.x * ChunkSize.x, (coords.z - 1) * ChunkSize.z),
					floorSize
				)
				var pixelFront = GetPixelInImage(
					floorImage,
					Vector2i(coords.x * ChunkSize.x, (coords.z + 1) * ChunkSize.z),
					floorSize
				)
				
				var chunk: Node3D = ChunkPool[GetChunkIndex(pixelCurrent.g)].duplicate()
				chunk.position = coords * ChunkSize
				
				ClonedChunkParent.add_child(chunk)
				LoadedChunks[coords] = chunk
				
				if ("Init" in chunk && "SetSeed" in chunk):
					chunk.BASE_WORLD_GENERATOR = self
					chunk.IsPlayerSpawn = pixelCurrent.b == 1 && pixelCurrent.b != pixelCurrent.g
					chunk.IsEntitySpawn = pixelCurrent.r == 1 && pixelCurrent.r != pixelCurrent.g
					chunk.Coords = coords
					chunk.Chunk_Left = GetChunkIndex(pixelLeft.g)
					chunk.Chunk_Right = GetChunkIndex(pixelRight.g)
					chunk.Chunk_Front = GetChunkIndex(pixelFront.g)
					chunk.Chunk_Back = GetChunkIndex(pixelBack.g)
					chunk.SetSeed(RNG.randi() + coords.x * 2 + coords.z * 4 - coords.y * 8)
					chunk.Init()
					
					if (chunk.IsPlayerSpawn):
						PlayerSpawns.append(chunk.position)
	
	for coords in LoadedChunks.keys():
		if (coords.distance_to(currentChunk) > Globals.ViewDistance):
			var chunkToRemove = LoadedChunks[coords]
			
			ClonedChunkParent.remove_child(chunkToRemove)
			chunkToRemove.queue_free()
			LoadedChunks.erase(coords)
	
	for floorID in LoadedMaps.keys():
		if (abs(floorID - currentChunk.y) > 5):
			LoadedMaps.erase(floorID)
	
	GenerationCompleted = true

func SpawnPlayer() -> void:
	var spawnPos = Vector3.ZERO
	
	if (PlayerSpawns.size() > 0):
		var idx = (randi() if (PlayerSpawnFullRandom) else RNG.randi()) % PlayerSpawns.size()
		spawnPos = PlayerSpawns[idx]
	else:
		spawnPos = Vector3(
			randi_range(PlayerSpawnMin.x, PlayerSpawnMax.x) if (PlayerSpawnFullRandom) else RNG.randi_range(PlayerSpawnMin.x, PlayerSpawnMax.x),
			randi_range(PlayerSpawnMin.y, PlayerSpawnMax.y) if (PlayerSpawnFullRandom) else RNG.randi_range(PlayerSpawnMin.y, PlayerSpawnMax.y),
			randi_range(PlayerSpawnMin.z, PlayerSpawnMax.z) if (PlayerSpawnFullRandom) else RNG.randi_range(PlayerSpawnMin.z, PlayerSpawnMax.z)
		)
	
	Player.global_position = spawnPos + PlayerSpawnOffset
	Player.Spawned = true

func _ready() -> void:
	FNL.noise_type = FastNoiseLite.TYPE_PERLIN
	FNL.frequency = 0.02
	FNL.fractal_type = FastNoiseLite.FRACTAL_FBM
	FNL.fractal_octaves = 5
	
	SetSeed(randi())
	
	InstancedChunkParent = Node3D.new()
	InstancedChunkParent.name = "Instanced"
	add_child(InstancedChunkParent)
	
	ClonedChunkParent = Node3D.new()
	ClonedChunkParent.name = "Cloned"
	add_child(ClonedChunkParent)
	
	for chunk in Chunks:
		var instance: Node3D = chunk.instantiate()
		instance.position = Vector3(-9999999, -9999999, -9999999)
		InstancedChunkParent.add_child(instance)
		
		ChunkPool.append(instance)
	
	if (!Multiplayer && !Generate):
		Generate = true
	elif (Multiplayer):
		if (LevelName not in MultiplayerConnection.VisitedLevels):
			MultiplayerConnection.VisitedLevels.append(LevelName)
		
		if (MultiplayerConnection.Socket.get_status() != StreamPeerTCP.STATUS_CONNECTED):
			if (Globals.Multiplayer_Debug):
				var randomUser = Globals.Multiplayer_Debug_Users.keys()[randi() % Globals.Multiplayer_Debug_Users.size()]
				
				Globals.User_Username = randomUser
				Globals.User_Password = Globals.Multiplayer_Debug_Users[randomUser]
			
			MultiplayerConnection.Connect(Globals.Multiplayer_Host, Globals.Multiplayer_Port)
			
			while (MultiplayerConnection.Socket.get_status() == StreamPeerTCP.STATUS_CONNECTING):
				MultiplayerConnection.Socket.poll()
				print("CONNECTING...")
				
				await get_tree().create_timer(2).timeout
			
			var loginResult = MultiplayerConnection.SendAndReceive("connect", [Globals.User_Username, Globals.User_Password])
			
			if (loginResult["code"] != "OK"):
				pass  # TODO: Error when logging in (probably incorrect credentials)
		
		var authResult = MultiplayerConnection.SendAndReceive("is_authorized")
		
		if (authResult["args"][0]):
			print("AUTHORIZED")
			Generate = true
		else:
			print("NO AUTHORIZED")
			pass  # TODO: Not authorized
	
	if (Generate):
		UpdateChunks()
		SpawnPlayer()
	
	var timer = Timer.new()
	timer.autostart = true
	timer.one_shot = false
	timer.wait_time = clampi(Globals.GenerationTime, 0.5, 20)
	timer.timeout.connect(UpdateChunks)
	add_child(timer)
	timer.start()

func _process(_Delta: float) -> void:
	MultiplayerConnection.Socket.poll()

func _physics_process(_Delta: float) -> void:
	if (PlayerDieFalling && Player.position.y <= -PlayerDieFallingDistance):
		Player.Die()
