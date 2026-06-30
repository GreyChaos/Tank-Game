extends Node

const MAPS = ["res://scenes/map_1.tscn", "res://scenes/map_2.tscn", "res://scenes/map_3.tscn", "res://scenes/map_4.tscn", "res://scenes/map_5.tscn"]
var Players = {}
var CPUS = {}
var DeadPlayers = []
var dead_cpus = []
signal gameOver
signal cleanShells
signal switchMaps(mapString: String)
var Powerups = []
var TeamA = []
var TeamB = []
var CPU_count = 0
var current_map = null
var game_in_progress = false

var current_gamemode: SceneManager.GameMode = SceneManager.GameMode.FFA

func playerDied(playerID: int) -> void:
	DeadPlayers.append(playerID)
	if (DeadPlayers.size() == Players.size() - 1):
			gameOver.emit()
	
func cleanUpShells() -> void:
	cleanShells.emit()
	
@rpc("authority","call_local","reliable")
func change_game_mode(new_gamemode: SceneManager.GameMode):
	current_gamemode = new_gamemode
