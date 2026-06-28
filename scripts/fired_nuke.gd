extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if multiplayer.is_server():
		$"Falling Timer".wait_time = randf_range(2, 2.5)
	$"Falling Timer".start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $Nukemark.frame == 6:
		$GPUParticles2D.emitting = true
		check_for_damage()


func _on_falling_timer_timeout() -> void:
	$Nukemark.play()
	$"Cleanup Timer".start()


func _on_cleanup_timer_timeout() -> void:
	queue_free()


func check_for_damage():
	for body in $Damage.get_overlapping_bodies():
		if body is CharacterBody2D:
			var hitPlayerID = str(body.name).to_int()
			if GameManager.Players.has(hitPlayerID):
				var playerName = GameManager.Players[hitPlayerID].name
				body.takeDamage.rpc(hitPlayerID, 2)
