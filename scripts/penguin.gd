extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_shot_by_player_body_entered(body: Node2D) -> void:
	if body.get_parent() is shell:
		body.get_parent().fired_by.takeDamage(str(body.get_parent().fired_by.name).to_int(), 1)
	queue_free()
