extends CharacterBody2D
class_name CPU

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
var robot_name = "null"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	spawn_cords = global_position
	flashTween = create_tween()
	flashTween.set_loops()
	flashTween.tween_property(self, "modulate:a", .3, .8)
	flashTween.tween_property(self, "modulate:a", 1.0, .8)
	modulate.a = 1.0
	flashTween.pause()
	name_color = $Name.modulate
	$Name.text = robot_name

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		if $NavigationAgent2D.is_navigation_finished():
			velocity = Vector2.ZERO
			return
		var next_path_pos = $NavigationAgent2D.get_next_path_position()
		var direction = global_position.direction_to(next_path_pos)
		velocity = Vector2.RIGHT.rotated(rotation) * speed
		rotation = lerp_angle(rotation, direction.angle(), 2 * delta)
		move_and_slide()
		if $RayCast2D.is_colliding():
			if $ShootCooldown.is_stopped():
				if GameManager.current_gamemode == SceneManager.GameMode.CTF:
					if GameManager.TeamA.has(self) and GameManager.TeamA.has($RayCast2D.get_collider()):
						return
					if GameManager.TeamB.has(self) and GameManager.TeamB.has($RayCast2D.get_collider()):
						return
				rpc("spawnShell", $BulletSpawn.global_position, $BulletSpawn.global_rotation + PI)
				$ShootCooldown.start()


func _on_update_target_timeout() -> void:
	if multiplayer.is_server():
		$NavigationAgent2D.target_position = get_closest_player()


func get_closest_player() -> Vector2:
	var closest_player_distance = INF
	var closest_player_cords = Vector2.ZERO
	# If you have the flag, run home
	if flag_being_held:
		if GameManager.TeamA.has(self):
			var flagSpot = $"../../".get_team_flag(FlagSpot.TeamLabel.A)
			return flagSpot.global_position
		if GameManager.TeamB.has(self):
			var flagSpot = $"../../".get_team_flag(FlagSpot.TeamLabel.B)
			return flagSpot.global_position
	# Check for own flag if CTF
	if GameManager.current_gamemode == SceneManager.GameMode.CTF:
		if GameManager.TeamA.has(self):
			var flagSpot = $"../../".get_team_flag(FlagSpot.TeamLabel.A)
			if !flagSpot.has_flag or flagSpot.starting_flag_spot != flagSpot.global_position:
				return flagSpot.local_flag.global_position
		if GameManager.TeamB.has(self):
			var flagSpot = $"../../".get_team_flag(FlagSpot.TeamLabel.B)
			if !flagSpot.has_flag or flagSpot.starting_flag_spot != flagSpot.global_position:
				return flagSpot.local_flag.global_position
	# Check for enemy flag if CTF and enemy not within PriorityTrigger
	var bodies_in_priority = $PriorityTarger.get_overlapping_bodies()
	for body in bodies_in_priority:
		if body in GameManager.DeadPlayers:
			continue
		if GameManager.TeamA.has(self) and GameManager.TeamA.has(body):
			continue
		if GameManager.TeamB.has(self) and GameManager.TeamB.has(body):
			continue
		if GameManager.TeamA.has(self) and GameManager.TeamA.has(body):
			continue
		if GameManager.TeamB.has(self) and GameManager.TeamB.has(body):
			continue
		return body.global_position
	# Continue to flag
	if GameManager.current_gamemode == SceneManager.GameMode.CTF:
		if GameManager.TeamA.has(self):
			var flagSpot = $"../../".get_team_flag(FlagSpot.TeamLabel.B)
			if flagSpot.has_flag:
				return flagSpot.global_position
		if GameManager.TeamB.has(self):
			var flagSpot = $"../../".get_team_flag(FlagSpot.TeamLabel.A)
			if flagSpot.has_flag:
				return flagSpot.global_position
	# Check for players, ignoring teammaps, and dead players
	for player in GameManager.Players.values():
		if player.id in GameManager.DeadPlayers:
			continue
		if GameManager.current_gamemode == SceneManager.GameMode.CTF:
			if GameManager.TeamA.has(self) and GameManager.TeamA.has(player.playerObject):
				continue
			if GameManager.TeamB.has(self) and GameManager.TeamB.has(player.playerObject):
				continue
		var player_pos = player.playerObject.global_position
		if position.distance_squared_to(player_pos) < closest_player_distance:
			closest_player_distance = position.distance_squared_to(player_pos)
			closest_player_cords = player_pos
	for player in GameManager.CPUS.values():
		if GameManager.current_gamemode == SceneManager.GameMode.CTF:
			if GameManager.TeamA.has(self) and GameManager.TeamA.has(player):
				continue
			if GameManager.TeamB.has(self) and GameManager.TeamB.has(player):
				continue
		if player == self or player in GameManager.dead_cpus:
			continue
		var player_pos = player.global_position
		if position.distance_squared_to(player_pos) < closest_player_distance:
			closest_player_distance = position.distance_squared_to(player_pos)
			closest_player_cords = player_pos
	return closest_player_cords


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
			visible = false
			set_physics_process(false)
			$CollisionShape2D.set_deferred("disabled", true)
			$RespawnTimer.start()
			if flag_being_held != null:
				get_parent().get_parent().drop_flag(flag_being_held, global_position)
				flag_being_held = null
			position = spawn_cords
			return
		GameManager.dead_cpus.append(self)
		visible = false
		set_physics_process(false)
		$CollisionShape2D.set_deferred("disabled", true)
		queue_free()
	else:
		currentScale -= .05
		global_scale = Vector2(currentScale, currentScale)
		
func restart():
	# reset_base_stats() Powerups are disabled for these guys anyways, or atleast should be
	rotation = randf_range(0,360)
	visible = true
	set_physics_process(true)
	$CollisionShape2D.set_deferred("disabled", false)
	currentHealth = 3
	$Hearts.frame = 0
	currentScale = 1
	global_scale = Vector2(currentScale, currentScale)
	
func change_name_color(color: Color):
	$Name.modulate = color
