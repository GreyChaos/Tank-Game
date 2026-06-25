extends Node2D

var data: PowerupData = load("res://powerups/resources/nuke.tres")
var spawnedSpot
var playerAffected
var pickedUp = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Texture.texture = data.texture
	$Timer.wait_time = data.length
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.7, 1.7), 1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2(2, 2), 1).set_trans(Tween.TRANS_SINE)

# Pickup Logic
func _on_area_2d_body_entered(body: Node2D) -> void:
	if not pickedUp:
		if body is CharacterBody2D:
			var hitPlayerID = str(body.name).to_int()
			if GameManager.Players.has(hitPlayerID):
				if body.powerData != null:
					return
				body.apply_powerup(data)
				playerAffected = body
				visible = false
				if data.use_timer:
					$Timer.start()
				pickedUp = true
				$PickupSound.play()


func _on_timer_timeout() -> void:
	GameManager.Powerups.erase(self)
	if spawnedSpot == null:
		print("Spawned Spot Null")
		return
	spawnedSpot.hasItem = false
	playerAffected.reset_base_stats()
	queue_free()
	
	
func early_clear() -> void:
	$Timer.timeout()
