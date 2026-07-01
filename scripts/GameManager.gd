extends Node

const MAPS = ["res://scenes/map_1.tscn", "res://scenes/map_2.tscn", "res://scenes/map_3.tscn", "res://scenes/map_4.tscn", "res://scenes/map_5.tscn"]
var Players = {}
var CPUS = {}
var DeadPlayers = []
var dead_cpus = []
signal gameOver
signal cleanShells
signal server_data_received
signal switchMaps(mapString: String)
var Powerups = []
var TeamA = []
var TeamB = []
var CPU_count = 0
var current_map = null
var game_in_progress = false
# Handle when all players have loaded, and ready to start
signal start_game
signal map_loaded
var ready_players = []

var current_gamemode: SceneManager.GameMode

func _ready() -> void:
	map_loaded.connect(_map_loaded.rpc)

func playerDied(playerID: int) -> void:
	DeadPlayers.append(playerID)
	if (DeadPlayers.size() == Players.size() - 1):
			gameOver.emit()
	
func cleanUpShells() -> void:
	cleanShells.emit()
	
@rpc("authority","call_local","reliable")
func change_game_mode(new_gamemode: SceneManager.GameMode):
	current_gamemode = new_gamemode


@rpc("any_peer","call_local","reliable")
func _map_loaded():
	var player_id = multiplayer.get_remote_sender_id()
	if multiplayer.is_server():      
		ready_players.append(player_id)
		if ready_players.size() == Players.size():
			start_game_signal.rpc()
			
@rpc("authority","call_local","reliable")
func start_game_signal():
	start_game.emit()
