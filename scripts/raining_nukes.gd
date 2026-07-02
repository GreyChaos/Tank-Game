extends Timer

const FIRED_NUKE = preload("res://scenes/fired_nuke.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_timeout() -> void:
	if multiplayer.is_server():
		var nuke = FIRED_NUKE.instantiate()
		nuke.position = Vector2(randi_range(-1152, 1152), randi_range(-648, 648))
		$"../PlayersContainer".add_child(nuke, true)
