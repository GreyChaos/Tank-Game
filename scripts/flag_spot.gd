extends Area2D

var local_flag
var has_flag = true
var player_with_flag = null
enum TeamLabel{
	A,
	B
}
var starting_flag_spot

@export var team: TeamLabel = TeamLabel.A

func _ready() -> void:
	local_flag = $Flag
	starting_flag_spot = global_position

func _physics_process(delta: float) -> void:
	if !has_flag:
		$Flag.global_position = player_with_flag.global_position

func _on_area_entered(area: Area2D) -> void:
	var player = area.get_parent()
	if player is PlayerTank:
		# Check to see if player can return flag
		if GameManager.TeamA.has(player) and team == TeamLabel.A and global_position != starting_flag_spot:
			reset_flag()
		if GameManager.TeamB.has(player) and team == TeamLabel.B and global_position != starting_flag_spot:
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
			var player_name = str(GameManager.Players[str(player.name).to_int()].name)
			var player_color = GameManager.Players[str(player.name).to_int()].playerObject.name_color.to_html(false)
			$"..".start_broadcast("[color=#" + player_color + "]" + player_name + "[/color] has taken a flag!")
		# Check to see if player is returning a flag
		if GameManager.TeamA.has(player) and team == TeamLabel.A:
			if player.flag_being_held != local_flag and player.flag_being_held != null:
				for playerb in GameManager.TeamB:
					GameManager.current_gamemode = SceneManager.GameMode.FFA
					if GameManager.TeamA.size() > 1:
						$"..".start_broadcast("Congrats [color=AQUAMARINE]Team A[/color], but\nTHERE CAN ONLY BE ONE\nFREE FOR ALL!")
					playerb.takeDamage(str(playerb.name).to_int(), 10)
					queue_free()
		if GameManager.TeamB.has(player) and team == TeamLabel.B:
			if player.flag_being_held != local_flag and player.flag_being_held != null:
				for playera in GameManager.TeamA:
					GameManager.current_gamemode = SceneManager.GameMode.FFA
					if GameManager.TeamB.size() > 1:
						$"..".start_broadcast("Congrats [color=crimson]Team B[/color], but\nTHERE CAN ONLY BE ONE\nFREE FOR ALL!")
					playera.takeDamage(str(playera.name).to_int(), 10)
					queue_free()

func reset_flag(): ## Resets flag back to original spot
	global_position = starting_flag_spot
	$Flag.global_position = global_position
	has_flag = true
	player_with_flag = null
	
func drop_flag(dropped_spot: Vector2): ## Drops a flag where the player died
	if team == TeamLabel.A:
		$"..".start_broadcast("[color=AQUAMARINE]Team A[/color], Flag dropped!")
	if team == TeamLabel.B:
		$"..".start_broadcast("[color=crimson]Team B[/color], Flag dropped!")
	global_position = dropped_spot
	has_flag = true
	player_with_flag = null
	$Flag.global_position = global_position
