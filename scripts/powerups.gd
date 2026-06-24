extends Node2D

@export var SpeedPower : Node2D
@export var FastShootPower : Node2D
@export var HealthPower : Node2D

var powerupList = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	powerupList.append(SpeedPower)
	powerupList.append(FastShootPower)
	powerupList.append(HealthPower)
	pass # Replace with function body.



func _on_powerup_spawn_timer_timeout() -> void:
	if not multiplayer.is_server():
		return
	var randomPowerupIndex = randi() % powerupList.size()
	var randomSpawnIndex = randi() % get_tree().get_nodes_in_group("PowerSpawnPoint").size()
	if get_tree().get_nodes_in_group("PowerSpawnPoint")[randomSpawnIndex].hasItem:
		return
	spawnPowers.rpc(randomPowerupIndex, randomSpawnIndex)


@rpc("authority", "call_local")
func spawnPowers(powerupIndex: int, spawnIndex: int):
	var currentPowerUp = powerupList[powerupIndex].duplicate()
	currentPowerUp.spawnedSpot = get_tree().get_nodes_in_group("PowerSpawnPoint")[spawnIndex]
	currentPowerUp.spawnedSpot.hasItem = true
	add_child(currentPowerUp)
	GameManager.Powerups.append(currentPowerUp)
	currentPowerUp.global_position = get_tree().get_nodes_in_group("PowerSpawnPoint")[spawnIndex].global_position
	
