extends RichTextLabel
@export var PlayerScene : PackedScene
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.gameOver.connect(gameOver)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$"../RestartText".text = "Restarting in: " + "%0.1f" % $"../../RestartTimer".time_left

func gameOver() -> void:
	visible = true
	$"../RestartText".visible = true
	$"../../RestartTimer".start()
	if GameManager.DeadPlayers.has(multiplayer.get_unique_id()):
		$"../YouLose".visible = true
		GameManager.Players[multiplayer.get_unique_id()].hat = $"../..".winning_hat
		GameManager.Players[multiplayer.get_unique_id()].playerObject.loser()
		GameManager.Players[multiplayer.get_unique_id()].wasWinner = false
	else:
		$"../YouWin".visible = true
		GameManager.Players[multiplayer.get_unique_id()].hat = $"../..".winning_hat
		GameManager.Players[multiplayer.get_unique_id()].playerObject.winner()
		GameManager.Players[multiplayer.get_unique_id()].wasWinner = true
		


func _on_restart_timer_timeout() -> void:
	if multiplayer.is_server():
		cleanup_data.rpc()
		GameManager.switchMaps.emit(GameManager.MAPS[randi_range(0, GameManager.MAPS.size() - 1)])
		

@rpc("authority", "call_local", "reliable")
func cleanup_data():
	GameManager.CPUS.clear()
	GameManager.TeamA.clear()
	GameManager.TeamB.clear()
	GameManager.cleanUpShells()
	for powerup in GameManager.Powerups:
		if powerup.spawnedSpot.hasItem:
			powerup.spawnedSpot.hasItem = false
			powerup.queue_free()
	GameManager.Powerups.clear()
	visible = false
	$"../RestartText".visible = false
	$"../YouWin".visible = false
	$"../YouLose".visible = false
	GameManager.DeadPlayers.clear()
	for Player in GameManager.Players:
		GameManager.Players[Player]["playerObject"].restart()
