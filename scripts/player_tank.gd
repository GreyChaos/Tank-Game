extends CharacterBody2D


var SPEED = 75.0
var ROTATESPEED = 75.0 / 5
const SHELLSCENE = preload("res://scenes/shell.tscn")
var currentHealth = 3
var maxHealth = 3
var currentScale = 1
var spawnPoint = null
var hasPower = false
var cameraSetup = false
@onready var camera = $Camera2D

func _ready() -> void:
	if GameManager.Players[multiplayer.get_unique_id()].wasWinner:
		winner()
	$TankSprite.modulate = GameManager.Players[multiplayer.get_unique_id()].color
	$Name.text = GameManager.Players[multiplayer.get_unique_id()].name
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	GameManager.Players[str(name).to_int()].playerObject = self
	$MultiplayerSynchronizer.delta_synchronized.connect(_on_synchronized)
	
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
		# Handle shoot.
		if Input.is_action_just_pressed("shoot") or $ShootCooldown.wait_time == .1:
			if $ShootCooldown.is_stopped():
				rpc("spawnShell", $BulletSpawn.global_position, $BulletSpawn.global_rotation)
				$ShootCooldown.start()
				
				#GameManager.gameOver.emit()
				#GameManager.switchMaps.emit("res://scenes/map_1.tscn")
				
			
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

@rpc("any_peer", "call_local")
func spawnShell(spawnPOS: Vector2, spawnROT: float):
	var shell = SHELLSCENE.instantiate()
	shell.position = spawnPOS
	shell.rotation = spawnROT
	$ShootParticle.emitting = true
	get_parent().add_child(shell)
	
func activatePowerUp(timerLength: float, moveSpeed: float, healthChange: int):
	if healthChange > 0 and currentHealth < maxHealth:
		currentHealth += healthChange
		$Hearts.frame -= healthChange
		if $Hearts.frame < 0:
			$Hearts.frame = 0
	$ShootCooldown.wait_time = timerLength
	SPEED = moveSpeed
	ROTATESPEED = moveSpeed / 5
	pass
	
func takeDamage(hitPlayerID: int):
	$DamageParticle.emitting = true
	$Hearts.frame += 1
	currentHealth -= 1
	$hitSound.play()
	if currentHealth == 0:
		GameManager.playerDied(GameManager.Players[hitPlayerID].id)
		visible = false
		set_physics_process(false)
		$CollisionShape2D.set_deferred("disabled", true)
	else:
		currentScale -= .05
		global_scale = Vector2(currentScale, currentScale)
		
		
func winner():
	$Hat.visible = true
	
	
func loser():
	$Hat.visible = false
		
func restart():
	hasPower = false
	SPEED = 75.0
	ROTATESPEED = 75.0 / 5
	$ShootCooldown.wait_time = .6
	rotation = randf_range(0,360)
	global_position = spawnPoint.global_position
	visible = true
	set_physics_process(true)
	$CollisionShape2D.set_deferred("disabled", false)
	currentHealth = 3
	$Hearts.frame = 0
	currentScale = 1
	global_scale = Vector2(currentScale, currentScale)
