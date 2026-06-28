extends CharacterBody2D

var speed = 75
const SHELLSCENE = preload("res://scenes/shell.tscn")
var currentHealth = 3
var maxHealth = 3
var currentScale = 1
var powerData : PowerupData = null
var cameraSetup = false
var next_shot_power = false
var flashTween
var flag_being_held = null
const FIRED_NUKE = preload("res://scenes/fired_nuke.tscn")
var spawn_cords : Vector2
var name_color


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	flashTween = create_tween()
	flashTween.set_loops()
	flashTween.tween_property(self, "modulate:a", .3, .8)
	flashTween.tween_property(self, "modulate:a", 1.0, .8)
	modulate.a = 1.0
	flashTween.pause()

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


@rpc("any_peer", "call_local", "reliable")
func cpu_takeDamage(damageAmount: int):
	# Flash while immune to damage
	flashTween.play()
	if !$DamageCooldown.is_stopped():
		return
	$DamageCooldown.start()
	$DamageParticle.emitting = true
	$Hearts.frame += damageAmount
	currentHealth -= damageAmount
	$hitSound.play()
	if currentHealth <= 0:
		if GameManager.current_gamemode == SceneManager.GameMode.CTF:
			# restart() DONT FORGET TO UNDO THIS LATER WHEN YOUR LIKE WHY DOESNT IT WORK
			position = spawn_cords
			if flag_being_held != null:
				get_parent().get_parent().reset_flag(flag_being_held)
				flag_being_held = null
			return
		# GameManager.playerDied(GameManager.Players[hitPlayerID].id)
		visible = false
		set_physics_process(false)
		$CollisionShape2D.set_deferred("disabled", true)
	else:
		currentScale -= .05
		global_scale = Vector2(currentScale, currentScale)
