extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(0.01, 0.01), 6).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(on_reached_min_scale)
	tween.tween_property(self, "scale", Vector2(.7, .7), 6).set_trans(Tween.TRANS_SINE)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	rotate(1 * delta)
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		body.rotation += 180
	if body.get_parent().is_in_group("shell"):
		body.get_parent().rotation += 180
	

func on_reached_min_scale():
	if multiplayer.is_server():
		var newSpot = Vector2(randf_range(-500, 500), randf_range(-230, 270))
		moveSpot.rpc(newSpot)

@rpc("authority", "call_local", "reliable")
func moveSpot(newSpot: Vector2):
	global_position = newSpot
