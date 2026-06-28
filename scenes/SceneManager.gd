extends Node2D
class_name SceneManager

@export var PlayerScene : PackedScene
@export var CameraSize = Vector2(576, 324)
@export var winning_hat = 0
enum GameMode{
	FFA,
	CTF
}
@export var gamemode: GameMode = GameMode.FFA

func _ready() -> void:
	GameManager.current_gamemode = gamemode
	$MultiplayerSpawner.spawn_function = _spawn_player
	var spawnPoints = get_tree().get_nodes_in_group("PlayerSpawnPoint")
	if gamemode == GameMode.FFA:
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

		if gamemode == GameMode.CTF:
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
		})
		index += 1

func _spawn_player(data: Dictionary) -> Node:
	var player = PlayerScene.instantiate()
	player.name = str(data["id"])
	player.position = data["pos"]
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
	
func reset_flag(flag: Sprite2D):
	flag.get_parent().reset_flag()

func _physics_process(delta: float) -> void:
	if gamemode == GameMode.CTF:
		pass

func start_broadcast(message: String):
	$CanvasLayer/Broadcast.text = message
	$CanvasLayer/BroadcastTimer.start()

func _on_broadcast_timer_timeout() -> void:
	$CanvasLayer/Broadcast.text = ""
