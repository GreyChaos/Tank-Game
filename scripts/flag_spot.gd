extends Area2D

var local_flag
var has_flag = true
var player_with_flag = null
enum TeamLabel{
	A,
	B
}

@export var team: TeamLabel = TeamLabel.A

func _ready() -> void:
	local_flag = $Flag

func _physics_process(delta: float) -> void:
	if !has_flag:
		$Flag.global_position = player_with_flag.global_position

func _on_area_entered(area: Area2D) -> void:
	var player = area.get_parent()
	if player is CharacterBody2D:
		# Check to see if player can pick up flag
		if has_flag and player.flag_being_held == null:
			if GameManager.TeamA.has(player) and team == TeamLabel.A:
				return
			if GameManager.TeamB.has(player) and team == TeamLabel.B:
				return
			has_flag = false
			player.flag_being_held = $Flag
			player_with_flag = player
		# Check to see if player is returning a flag
		if GameManager.TeamA.has(player) and team == TeamLabel.A:
			if player.flag_being_held != local_flag and player.flag_being_held != null:
				for playerb in GameManager.TeamB:
					GameManager.current_gamemode = SceneManager.GameMode.FFA
					playerb.takeDamage(str(playerb.name).to_int(), 10)
		if GameManager.TeamB.has(player) and team == TeamLabel.B:
			if player.flag_being_held != local_flag and player.flag_being_held != null:
				for playera in GameManager.TeamA:
					GameManager.current_gamemode = SceneManager.GameMode.FFA
					playera.takeDamage(str(playera.name).to_int(), 10)

func reset_flag():
	$Flag.global_position = global_position
	print(global_position)
	has_flag = true
	player_with_flag = null
