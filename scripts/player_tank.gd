extends CharacterBody2D

# base 75
var SPEED = 75.0
var ROTATESPEED = 75.0 / 3
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
@onready var camera = $Camera2D

func _ready() -> void:
	if GameManager.Players[multiplayer.get_unique_id()].wasWinner:
		winner()
	spawn_cords = global_position
	$TankSprite.modulate = GameManager.Players[multiplayer.get_unique_id()].color
	$Name.text = GameManager.Players[multiplayer.get_unique_id()].name
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	GameManager.Players[str(name).to_int()].playerObject = self
	$MultiplayerSynchronizer.delta_synchronized.connect(_on_synchronized)
	flashTween = create_tween()
	flashTween.set_loops()
	flashTween.tween_property(self, "modulate:a", .3, .8)
	flashTween.tween_property(self, "modulate:a", 1.0, .8)
	modulate.a = 1.0
	flashTween.pause()
	if has_meta("camera_size"):
		var camera_size = get_meta("camera_size")
		if multiplayer.get_unique_id() == name.to_int():
			camera.make_current()
			camera.limit_bottom = camera_size[1]
			camera.limit_right = camera_size[0]
			camera.limit_left = -camera_size[0]
			camera.limit_top = -camera_size[1]
		else:
			camera.enabled = false
	
func _on_synchronized():
	if cameraSetup:
		return
	cameraSetup = true
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		camera.make_current()
	else:
		camera.queue_free()

func _physics_process(delta: float) -> void:
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		#Debug K to Kill
		if Input.is_action_just_pressed("kill_player"):
			takeDamage.rpc(multiplayer.get_unique_id(), 3)
		# Handle shoot.
		if Input.is_action_just_pressed("shoot") or $ShootCooldown.wait_time == .1:
			if $ShootCooldown.is_stopped():
				rpc("spawnShell", $BulletSpawn.global_position, $BulletSpawn.global_rotation)
				$ShootCooldown.start()
				
			
		# Handle foward/back
		var direction := Input.get_axis("backward", "foward")
		if direction:
			if direction > 0:
				$TankSprite.play("moving_foward")
			elif direction < 0:
				$TankSprite.play("moving_backward")
			velocity = Vector2.UP.rotated(rotation) * direction * SPEED
		else:
			$TankSprite.play("idle")
			velocity = velocity.move_toward(Vector2.ZERO, SPEED * delta * 10)
			
		# Handle rotation
		var rotationamount := Input.get_axis("left", "right")
		if rotationamount:
			rotation += rotationamount * delta

		move_and_slide()

@rpc("any_peer", "call_local", "reliable")
func spawnShell(spawnPOS: Vector2, spawnROT: float):
	if next_shot_power:
		next_shot_power = false
		if powerData.name == "Nuke":
			for i in range(25):
				var nuke = FIRED_NUKE.instantiate()
				nuke.position = Vector2(randi_range(-576, 576), randi_range(-324, 324))
				get_parent().add_child(nuke)
		if powerData.name == "Big Shot":
			var shell = SHELLSCENE.instantiate()
			shell.position = spawnPOS
			shell.rotation = spawnROT
			shell.fired_by = self
			$ShootParticle.emitting = true
			shell.scale *= powerData.shell_scale
			shell.speed = powerData.shell_speed
			shell.immune_to_objects = powerData.shell_immune
			get_parent().add_child(shell)
		if powerData.name == "Triple Shot":
			rpc("spawnShell", $BulletSpawn.global_position, $BulletSpawn.global_rotation)
			rpc("spawnShell", $BulletSpawn2.global_position, $BulletSpawn2.global_rotation)
			rpc("spawnShell", $BulletSpawn3.global_position, $BulletSpawn3.global_rotation)
		if powerData.name == "360 Shot":
			var spawn_count = 15
			var radius = 50.0
			var angle_step = TAU / spawn_count
			for i in range(spawn_count):
				var current_angle = i * angle_step
				var offset = Vector2(cos(current_angle), sin(current_angle)) * radius
				rpc("spawnShell", global_position + offset, current_angle)
		powerData = null
	else:
		var shell = SHELLSCENE.instantiate()
		shell.position = spawnPOS
		shell.rotation = spawnROT
		shell.fired_by = self
		$ShootParticle.emitting = true
		get_parent().add_child(shell)


func apply_powerup(powerup: PowerupData):
	$PowerupPartical.emitting = true
	powerData = powerup
	# Health
	if powerup.health_change > 0 and currentHealth < maxHealth:
		currentHealth += powerup.health_change
		$Hearts.frame -= powerup.health_change
		if $Hearts.frame < 0:
			$Hearts.frame = 0
	# Speed
	SPEED = powerup.move_speed
	ROTATESPEED = powerup.move_speed / 5
	# Shoot Time
	$ShootCooldown.wait_time = powerup.shoot_speed
	# Shell Data
	next_shot_power = powerup.fire_to_trigger
	
func reset_base_stats():
	SPEED = 75.0
	ROTATESPEED = 75.0 / 3
	$ShootCooldown.wait_time = .6
	powerData = null
	

@rpc("any_peer", "call_local", "reliable")
func takeDamage(hitPlayerID: int, damageAmount: int):
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
			restart()
			position = spawn_cords
			if flag_being_held != null:
				get_parent().get_parent().reset_flag(flag_being_held)
				flag_being_held = null
			return
		GameManager.playerDied(GameManager.Players[hitPlayerID].id)
		visible = false
		set_physics_process(false)
		$CollisionShape2D.set_deferred("disabled", true)
	else:
		currentScale -= .05
		global_scale = Vector2(currentScale, currentScale)
		
		
func winner():
	$Hat.frame = GameManager.Players[multiplayer.get_unique_id()].hat
	$Hat.visible = true
	
	
func loser():
	$Hat.visible = false
		
func restart():
	reset_base_stats()
	rotation = randf_range(0,360)
	visible = true
	set_physics_process(true)
	$CollisionShape2D.set_deferred("disabled", false)
	currentHealth = 3
	$Hearts.frame = 0
	currentScale = 1
	global_scale = Vector2(currentScale, currentScale)


func _on_damage_cooldown_timeout() -> void:
	flashTween.pause()
	modulate.a = 1.0
