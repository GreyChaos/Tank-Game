extends Node2D

var player_in_control
var players_and_timers = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if GameManager.current_gamemode == SceneManager.GameMode.KOTH:
		self.show()
		update_hill_progress()
		
	


func _on_hill_body_entered(area: Area2D) -> void:
	if player_in_control == null:
		player_in_control = area.get_parent()
		if player_in_control not in players_and_timers:
			players_and_timers[player_in_control] = {
				"Timer": Timer.new()
			}
			players_and_timers[player_in_control].Timer.wait_time = $HillControlTimer.wait_time
			players_and_timers[player_in_control].Timer.timeout.connect(_on_hill_timer_timeout)
			players_and_timers[player_in_control].Timer.one_shot = true
			add_child(players_and_timers[player_in_control].Timer)
			players_and_timers[player_in_control].Timer.start()
		else:
			players_and_timers[player_in_control].Timer.paused = false


func _on_hill_body_exited(area: Area2D) -> void:
	if player_in_control == area.get_parent():
		players_and_timers[player_in_control].Timer.paused = true
		player_in_control = null
		for body in $Hill.get_overlapping_areas():
			if body.get_parent() is CharacterBody2D:
				_on_hill_body_entered(body)
		
func _on_hill_timer_timeout():
	if multiplayer.is_server():
		$"CanvasLayer/Hill Progress".text = ""
		# $"CanvasLayer/Hill Progress".text = str(GameManager.Players[player_in_control.name.to_int()].name) + " has won!" 		Add this later to show the winner with text
		var loser_players = GameManager.Players.duplicate()
		loser_players.erase(player_in_control.name.to_int())
		GameManager.DeadPlayers.clear()
		GameManager.change_game_mode.rpc(SceneManager.GameMode.FFA)
		for player in loser_players:
			player = GameManager.Players[player].playerObject
			if not player.has_method("cpu_deal_damage"):
				player.deal_damage.rpc(str(player.name).to_int(), 10)
		end_game_for_all.rpc()
		
		
@rpc("authority","call_local","reliable")
func end_game_for_all():
	GameManager.gameOver.emit()
		

func update_hill_progress():
	if multiplayer.is_server():
		if player_in_control != null:
			$"CanvasLayer/Hill Progress".text = str(GameManager.Players[player_in_control.name.to_int()].name) + " %0.1f" % players_and_timers[player_in_control].Timer.time_left + " Seconds to win!"
		else:
			$"CanvasLayer/Hill Progress".text = "Nobody on the hill!"
