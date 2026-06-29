extends Node2D
var damage_checked = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$"Falling Timer".wait_time = randf_range(2, 2.5)
	$"Falling Timer".start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if $Nukemark.frame == 6 and !damage_checked:
		damage_checked = true
		$GPUParticles2D.emitting = true
		check_for_damage()


func _on_falling_timer_timeout() -> void:
	$Nukemark.play()
	$"Cleanup Timer".start()


func _on_cleanup_timer_timeout() -> void:
	if multiplayer.is_server():
		queue_free()


func check_for_damage():
	$ExplodeNoise.play()
	if !multiplayer.is_server():
		return
	for body in $Damage.get_overlapping_bodies():
		if body is CharacterBody2D:
			var hitPlayerID = str(body.name).to_int()
			if body.has_method("cpu_deal_damage"):
				body.cpu_deal_damage(2)
			elif GameManager.Players.has(hitPlayerID):
				body.deal_damage.rpc(hitPlayerID, 2)
				
				
