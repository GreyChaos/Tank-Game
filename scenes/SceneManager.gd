extends Node2D

@export var PlayerScene : PackedScene
@export var CameraSize = Vector2(576, 324)
@export var winning_hat = 0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var spawnPoints = get_tree().get_nodes_in_group("PlayerSpawnPoint")
	spawnPoints.shuffle()
	var index = 0
	for i in GameManager.Players:
		var currentPlayer = PlayerScene.instantiate()
		currentPlayer.name = str(GameManager.Players[i].id)
		add_child(currentPlayer)
		currentPlayer.global_position = spawnPoints[index].global_position
		currentPlayer.spawnPoint = spawnPoints[index]
		currentPlayer.rotation = randf_range(0, 360)
		if CameraSize != Vector2(576, 324):
			currentPlayer.camera.lerp()
		currentPlayer.camera.limit_bottom = CameraSize[1]
		currentPlayer.camera.limit_right = CameraSize[0]
		currentPlayer.camera.limit_left = -CameraSize[0]
		currentPlayer.camera.limit_top = -CameraSize[1]
		index += 1
