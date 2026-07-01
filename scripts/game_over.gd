extends RichTextLabel
@export var PlayerScene : PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.gameOver.connect(gameOver)
	GameManager.start_game.connect(startGame)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$"../RestartText".text = "Restarting in: " + "%0.1f" % $"../../RestartTimer".time_left


func startGame():
	visible = false
	$"../YouLose".visible = false
	$"../YouWin".visible = false
	$"../Losing Particles".restart()
	$"../Victory Particles".restart()
	$"../Losing Particles".emitting = false
	$"../Victory Particles".emitting = false

func gameOver() -> void:
	$"../BroadcastTimer".timeout.emit()
	visible = true
	$"../RestartText".visible = true
	$"../../RestartTimer".start()
	if GameManager.DeadPlayers.has(multiplayer.get_unique_id()):
		$"../LosingSound".play()
		$"../YouLose".visible = true
		$"../Losing Particles".emitting = true
		GameManager.Players[multiplayer.get_unique_id()].playerObject.loser()
		GameManager.Players[multiplayer.get_unique_id()].wasWinner = false
	else:
		$"../VictorySound".play()
		$"../YouWin".visible = true
		$"../Victory Particles".emitting = true
		GameManager.Players[multiplayer.get_unique_id()].playerObject.winner()
		GameManager.Players[multiplayer.get_unique_id()].wasWinner = true
		


func _on_restart_timer_timeout() -> void:
	if multiplayer.is_server():
		cleanup_data.rpc()
		# Exclude current map from rotation
		var valid_maps = GameManager.MAPS.duplicate()
		valid_maps.erase("res://scenes/" + str(GameManager.current_map))
		GameManager.switchMaps.emit(valid_maps[randi_range(0, GameManager.MAPS.size() - 2)])
		

@rpc("authority", "call_local", "reliable")
func cleanup_data():
	GameManager.ready_players.clear()
	$"../Victory Particles".emitting = false
	$"../Losing Particles".emitting = false
	GameManager.CPUS.clear()
	GameManager.TeamA.clear()
	GameManager.TeamB.clear()
	GameManager.cleanUpShells()
	for powerup in GameManager.Powerups:
		if is_instance_valid(powerup) and is_instance_valid(powerup.spawnedSpot):
			powerup.spawnedSpot.hasItem = false
			powerup.queue_free()
	GameManager.Powerups.clear()
	visible = false
	$"../RestartText".visible = false
	$"../YouWin".visible = false
	$"../YouLose".visible = false
	GameManager.DeadPlayers.clear()
