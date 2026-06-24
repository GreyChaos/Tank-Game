extends Node2D

const POWERUPS_FOLDER = "res://powerups/resources/"
var powerup_List : Array[PowerupData] = []
@export var powerup_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Load Powerups
	var dir = DirAccess.open(POWERUPS_FOLDER)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = POWERUPS_FOLDER + file_name
		var resource = load(full_path)
		powerup_List.append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()


func _on_powerup_spawn_timer_timeout() -> void:
	if not multiplayer.is_server():
		return
	var randomPowerupIndex = randi() % powerup_List.size()
	var randomSpawnIndex = randi() % get_tree().get_nodes_in_group("PowerSpawnPoint").size()
	if get_tree().get_nodes_in_group("PowerSpawnPoint")[randomSpawnIndex].hasItem:
		return
	spawnPowers.rpc(randomPowerupIndex, randomSpawnIndex)


@rpc("authority", "call_local", "reliable")
func spawnPowers(powerupIndex: int, spawnIndex: int):
	var currentPowerUp = powerup_scene.instantiate()
	currentPowerUp.data = powerup_List[powerupIndex]
	currentPowerUp.spawnedSpot = get_tree().get_nodes_in_group("PowerSpawnPoint")[spawnIndex]
	currentPowerUp.spawnedSpot.hasItem = true
	add_child(currentPowerUp)
	GameManager.Powerups.append(currentPowerUp)
	currentPowerUp.global_position = get_tree().get_nodes_in_group("PowerSpawnPoint")[spawnIndex].global_position
	
