class_name WorldGen extends Node3D

var MULTIPLAYER_PLAYER_SKIN: PackedScene = load("res://Prefabs/MultiplayerSkin.tscn")

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
var SpawnedMultiplayerPlayers: Dictionary[String, MultiplayerCharacter] = {}

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

func UpdateMultiplayer() -> void:
	if (!Multiplayer):
		return
	
	MultiplayerConnection.SetCurrentLevel(LevelName)
	MultiplayerConnection.SetPlayerPosition(Player.global_position)
	MultiplayerConnection.SetPlayerRotation(Player.global_rotation)
	MultiplayerConnection.SetPlayerScale(Player.scale)
	
	var players = MultiplayerConnection.GetAllPlayers()
	
	for p in players:
		if (p["Username"] == Globals.User_Username || p["CurrentLevel"] != LevelName):
			continue
		
		if (p["Username"] not in SpawnedMultiplayerPlayers):
			var playerNodeInWorld: MultiplayerCharacter = MULTIPLAYER_PLAYER_SKIN.instantiate()
			add_child(playerNodeInWorld)
			
			p["NodeInWorld"] = playerNodeInWorld
			SpawnedMultiplayerPlayers[p["Username"]] = playerNodeInWorld
		
		SpawnedMultiplayerPlayers[p["Username"]].global_position = Vector3(
			p["Position"][0],
			p["Position"][1],
			p["Position"][2]
		)
		SpawnedMultiplayerPlayers[p["Username"]].global_rotation = Vector3(
			p["Rotation"][0],
			p["Rotation"][1],
			p["Rotation"][2]
		)
		SpawnedMultiplayerPlayers[p["Username"]].scale = Vector3(
			p["Scale"][0],
			p["Scale"][1],
			p["Scale"][2]
		)
		SpawnedMultiplayerPlayers[p["Username"]].SetCrouched(p["Crouched"])
		SpawnedMultiplayerPlayers[p["Username"]].SetNameTag(p["Username"])

func _ready() -> void:
	FNL.noise_type = FastNoiseLite.TYPE_PERLIN
	FNL.frequency = 0.02
	FNL.fractal_type = FastNoiseLite.FRACTAL_FBM
	FNL.fractal_octaves = 5
	
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
		SetSeed(randi())
	elif (Multiplayer):
		if (LevelName not in MultiplayerConnection.VisitedLevels):
			MultiplayerConnection.VisitedLevels.append(LevelName)
		if (!MultiplayerConnection.IsConnected()):
			if (Globals.Multiplayer_Debug):
				var randomUser = Globals.Multiplayer_Debug_Users.keys()[randi() % Globals.Multiplayer_Debug_Users.size()]
				
				Globals.User_Username = randomUser
				Globals.User_Password = Globals.Multiplayer_Debug_Users[randomUser]
			
			MultiplayerConnection.Connect(Globals.Multiplayer_Server)
		
		if (MultiplayerConnection.IsAuthorized(false) || MultiplayerConnection.Login(Globals.User_Username, Globals.User_Password, false)):
			Generate = true
		else:
			print("NOT LOGGED IN.")
			pass  # TODO: Error when logging in (probably incorrect credentials)
		
		var levelsData = MultiplayerConnection.GetLevelsData(false)
		var levelFound = false
		
		for level in levelsData:
			if (level["Name"] == LevelName):
				levelFound = true
				
				if (level["NoiseMaps"] != null):
					pass  # TODO: Download noise maps from server and set
				
				SetSeed(level["Seed"])
				# TODO: Set chunks disabled IDs
		
		if (!levelFound):
			push_error("Level NOT found in server. Setting random seed.")
			SetSeed(randi())
	
	if (Generate):
		UpdateChunks()
		SpawnPlayer()
	
	var genTimer = Timer.new()
	genTimer.autostart = true
	genTimer.one_shot = false
	genTimer.wait_time = clampf(Globals.GenerationTime, 0.5, 20)
	genTimer.timeout.connect(UpdateChunks)
	add_child(genTimer)
	
	if (Globals.Multiplayer_UpdateTime >= 0.1):
		var multiplayerTimer = Timer.new()
		multiplayerTimer.autostart = true
		multiplayerTimer.one_shot = false
		multiplayerTimer.wait_time = clampf(Globals.Multiplayer_UpdateTime, 0.05, 1)
		multiplayerTimer.timeout.connect(UpdateMultiplayer)
		add_child(multiplayerTimer)

func _process(_Delta: float) -> void:
	if (Globals.Multiplayer_UpdateTime < 0.1):
		UpdateMultiplayer()

func _physics_process(_Delta: float) -> void:
	if (PlayerDieFalling && Player.position.y <= -PlayerDieFallingDistance):
		Player.Die()
