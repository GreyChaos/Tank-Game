extends Camera2D

# Called when the node enters the scene tree for the first time.
func lerp():
	zoom = Vector2(.5,.5)
	var tween = create_tween().set_loops()
	tween.tween_property(self, "zoom", Vector2(1, 1), 1).set_trans(Tween.TRANS_SINE)
