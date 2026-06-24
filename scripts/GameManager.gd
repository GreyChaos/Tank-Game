extends Node

const MAPS = ["res://scenes/map_1.tscn", "res://scenes/map_2.tscn", "res://scenes/map_3.tscn",  "res://scenes/map_4.tscn"]
var Players = {}
var DeadPlayers = []
signal gameOver
signal cleanShells
signal switchMaps(mapString: String)
var Powerups = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func playerDied(playerID: int) -> void:
	DeadPlayers.append(playerID)
	if (DeadPlayers.size() == Players.size() - 1):
		gameOver.emit()
		
func cleanUpShells() -> void:
	cleanShells.emit()
