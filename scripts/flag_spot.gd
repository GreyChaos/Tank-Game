extends Area2D
class_name FlagSpot

var local_flag
var has_flag = true
var player_with_flag = null
enum TeamLabel{
	A,
	B
}
var starting_flag_spot
var game_over = false

@export var team: TeamLabel = TeamLabel.A

func _ready() -> void:
	local_flag = $Flag
	starting_flag_spot = global_position

func _physics_process(delta: float) -> void:
	if !has_flag and GameManager.current_gamemode == SceneManager.GameMode.CTF and multiplayer.is_server():
		$Flag.global_position = player_with_flag.global_position

func _on_area_entered(area: Area2D) -> void:
	if !multiplayer.is_server() or game_over or GameManager.current_gamemode != SceneManager.GameMode.CTF:
		return
	var player = area.get_parent()
	if player is CharacterBody2D:
		# Check to see if player can return flag
		if GameManager.TeamA.has(player) and team == TeamLabel.A and global_position != starting_flag_spot and has_flag:
			reset_flag()
		if GameManager.TeamB.has(player) and team == TeamLabel.B and global_position != starting_flag_spot and has_flag:
			reset_flag()
		# Check to see if player can pick up flag
		if has_flag and player.flag_being_held == null:
			if GameManager.TeamA.has(player) and team == TeamLabel.A:
				return
			if GameManager.TeamB.has(player) and team == TeamLabel.B:
				return
			has_flag = false
			player.flag_being_held = $Flag
			player_with_flag = player
			if player is PlayerTank:
				var player_name = str(GameManager.Players[str(player.name).to_int()].name)
				var player_color = GameManager.Players[str(player.name).to_int()].playerObject.name_color.to_html(false)
				$"..".start_broadcast("[color=#" + player_color + "]" + player_name + "[/color] has taken a flag!")
			else:
				$"..".start_broadcast("[color=#" + player.name_color.to_html() + "]" + "CPU" + "[/color] has taken a flag!")
		# Check to see if player is returning a flag
		if GameManager.TeamA.has(player) and team == TeamLabel.A:
			if player.flag_being_held != local_flag and player.flag_being_held != null:
				GameManager.change_game_mode.rpc(SceneManager.GameMode.FFA)
				GameManager.DeadPlayers.clear()
				for playerb in GameManager.TeamB:
					if not playerb.has_method("cpu_deal_damage"):
						playerb.deal_damage.rpc(str(playerb.name).to_int(), 10)
					end_game()
		if GameManager.TeamB.has(player) and team == TeamLabel.B:
			if player.flag_being_held != local_flag and player.flag_being_held != null:
				GameManager.change_game_mode.rpc(SceneManager.GameMode.FFA)
				GameManager.DeadPlayers.clear()
				for playera in GameManager.TeamA:
					if not playera.has_method("cpu_deal_damage"):
						playera.deal_damage.rpc(str(playera.name).to_int(), 10)
					end_game()

func end_game():
	game_over = true
	end_game_for_all.rpc()
	
@rpc("authority","call_local","reliable")
func end_game_for_all():
	GameManager.gameOver.emit()
	

func reset_flag(): ## Resets flag back to original spot
	if !multiplayer.is_server():
		return
	global_position = starting_flag_spot
	$Flag.global_position = global_position
	has_flag = true
	player_with_flag = null
	
	
@rpc("any_peer")
func request_flag_death(query_id: int):
	var sender_id = multiplayer.get_remote_sender_id()
	# Check if game is in progress, and can join
	if query_id == 1:
		drop_flag(GameManager.Players[sender_id].playerObject.global_position)
		rpc_id(sender_id, "recieve_data_from_server", true)


@rpc("authority")
func recieve_data_from_server(data):
	GameManager.server_data_received.emit(data)
	
	
func drop_flag(dropped_spot: Vector2): ## Drops a flag where the player died
	if !multiplayer.is_server():
		return
	if team == TeamLabel.A:
		$"..".start_broadcast("[color=AQUAMARINE]Team A[/color], Flag dropped!")
	if team == TeamLabel.B:
		$"..".start_broadcast("[color=crimson]Team B[/color], Flag dropped!")
	global_position = dropped_spot
	has_flag = true
	player_with_flag = null
	$Flag.global_position = global_position
