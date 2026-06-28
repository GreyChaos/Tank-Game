extends CharacterBody2D

var speed = 75
const SHELLSCENE = preload("res://scenes/shell.tscn")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if $NavigationAgent2D.is_navigation_finished():
		velocity = Vector2.ZERO
		return
	var next_path_pos = $NavigationAgent2D.get_next_path_position()
	var direction = global_position.direction_to(next_path_pos)
	velocity = direction * speed
	look_at(global_position + direction)
	move_and_slide()
	
	if $RayCast2D.is_colliding():
		if $ShootCooldown.is_stopped():
				rpc("spawnShell", $BulletSpawn.global_position, $BulletSpawn.global_rotation + PI)
				$ShootCooldown.start()


func _on_update_target_timeout() -> void:
	$NavigationAgent2D.target_position = GameManager.Players[1].playerObject.global_position


@rpc("any_peer", "call_local", "reliable")
func spawnShell(spawnPOS: Vector2, spawnROT: float):
	var shell = SHELLSCENE.instantiate()
	shell.position = spawnPOS
	shell.rotation = spawnROT
	shell.fired_by = self
	$ShootParticle.emitting = true
	get_parent().add_child(shell)
