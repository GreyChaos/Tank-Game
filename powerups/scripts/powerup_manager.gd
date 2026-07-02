extends Node2D

@export var powerup_scene : PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.start_game.connect(_bind_spawn_function)

	

func _bind_spawn_function():
	get_parent().get_node("PowerupSpawner").spawn_function = _spawn_powers
	
func _on_powerup_spawn_timer_timeout() -> void:
	if not multiplayer.is_server():
		return
	var randomPowerupIndex = randi() % PowerupDataLoader.powerup_List.size()
	var randomSpawnIndex = randi() % get_tree().get_nodes_in_group("PowerSpawnPoint").size()
	if get_tree().get_nodes_in_group("PowerSpawnPoint")[randomSpawnIndex].hasItem:
		return
	get_parent().get_node("PowerupSpawner").spawn({
		"powerup_index" : randomPowerupIndex,
		"powerup_spawn" : randomSpawnIndex
	})
	

func _spawn_powers(data: Dictionary) -> Node:
	var currentPowerUp = powerup_scene.instantiate()
	currentPowerUp.data = PowerupDataLoader.powerup_List[data.powerup_index]
	currentPowerUp.spawnedSpot = get_tree().get_nodes_in_group("PowerSpawnPoint")[data.powerup_spawn]
	currentPowerUp.spawnedSpot.hasItem = true
	GameManager.Powerups.append(currentPowerUp)
	currentPowerUp.global_position = get_tree().get_nodes_in_group("PowerSpawnPoint")[data.powerup_spawn].global_position
	return currentPowerUp
	
