extends Node2D
class_name SceneManager

var CPUScene = load("res://scenes/cpu.tscn")
@export var PlayerScene : PackedScene
@export var CameraSize = Vector2(576, 324)
@export var winning_hat = 0
enum GameMode{
	FFA,
	CTF,
	KOTH
}
@export var valid_gamemodes: Array[GameMode]

func _ready() -> void:
	if multiplayer.is_server():
		if GameManager.current_gamemode not in valid_gamemodes:
			GameManager.change_game_mode.rpc(valid_gamemodes.pick_random())
	$MultiplayerSpawner.spawn_function = _spawn_player
	var spawnPoints = get_tree().get_nodes_in_group("PlayerSpawnPoint")
	if GameManager.current_gamemode == GameMode.FFA:
		spawnPoints.shuffle()
	if multiplayer.is_server():
		spawn_players(spawnPoints)

func spawn_players(spawnPoints : Array) -> void:
	var index = 0
	var teamA_spawns = spawnPoints.filter(func(spawnpoint): return spawnpoint.name.begins_with("TeamA"))
	var teamB_spawns = spawnPoints.filter(func(spawnpoint): return spawnpoint.name.begins_with("TeamB"))
	for id in GameManager.Players:
		var team = 0
		var pos = Vector2.ZERO

		if GameManager.current_gamemode == GameMode.CTF:
			if index % 2 == 0:
				team = 2
				pos = teamB_spawns.pop_front().global_position
			else:
				team = 1
				pos = teamA_spawns.pop_front().global_position
		else:
			pos = spawnPoints.pop_front().global_position

		$MultiplayerSpawner.spawn({
			"id": id,
			"pos": pos,
			"team": team,
			"camera_size": CameraSize,
			"rotation": randf_range(0, 360)
		})
		index += 1
	var cpu_names = ["Bagelbot", "Craftulon", "Robopollo", "Botty", "Betty", "Berty", "Bloopy"]
	cpu_names.shuffle()
	for i in range(GameManager.CPU_count):
		if GameManager.current_gamemode == GameMode.CTF:
			var CPU = CPUScene.instantiate()
			if i % 2 == 0:
				GameManager.TeamA.append(CPU)
				CPU.change_name_color(Color.AQUAMARINE)
				CPU.global_position = teamA_spawns.pop_front().global_position
			else:
				GameManager.TeamB.append(CPU)
				CPU.change_name_color(Color.CRIMSON)
				CPU.global_position = teamB_spawns.pop_front().global_position
			GameManager.CPUS[i] = CPU
			CPU.robot_name = cpu_names.pop_front()
			$PlayersContainer.add_child(CPU, true)
		else:
			var CPU = CPUScene.instantiate()
			CPU.global_position = spawnPoints.pop_front().global_position
			GameManager.CPUS[i] = CPU
			CPU.robot_name = cpu_names.pop_front()
			$PlayersContainer.add_child(CPU, true)

func _spawn_player(data: Dictionary) -> Node:
	var player = PlayerScene.instantiate()
	player.name = str(data["id"])
	player.position = data["pos"]
	player.rotation = data["rotation"]
	player.set_meta("team", data["team"])
	player.set_meta("camera_size", data["camera_size"])

	if data["team"] != 0:
		if data["team"] == 2:
			GameManager.TeamB.append(player)
			player.change_name_color(Color.CRIMSON)
		else:
			GameManager.TeamA.append(player)
			player.change_name_color(Color.AQUAMARINE)
	else:
		player.change_name_color(Color.WHITE)
	return player

	
func drop_flag(flag: Sprite2D, pos: Vector2):
	flag.get_parent().drop_flag(pos)


func get_team_flag(team: FlagSpot.TeamLabel) -> Area2D:
	if team == FlagSpot.TeamLabel.A:
		return $FlagSpot
	elif team == FlagSpot.TeamLabel.B:
		return $FlagSpot2
	return null


func start_broadcast(message: String):
	$CanvasLayer/Broadcast.text = message
	$CanvasLayer/BroadcastTimer.start()

func _on_broadcast_timer_timeout() -> void:
	$CanvasLayer/Broadcast.text = ""
