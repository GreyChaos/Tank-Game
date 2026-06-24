extends Node2D

@export var shootSpeed = 0.6
@export var length = 5.0
@export var moveSpeed = 75
@export var texture: Texture2D
@export var healthChange = 0
var spawnedSpot
var playerAffected
var pickedUp = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Texture.texture = texture
	$Timer.wait_time = length
	var tween = create_tween().set_loops()
	tween.tween_property(self, "scale", Vector2(1.7, 1.7), 1).set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "scale", Vector2(2, 2), 1).set_trans(Tween.TRANS_SINE)

# Pickup Logic
func _on_area_2d_body_entered(body: Node2D) -> void:
	if not pickedUp:
		if body is CharacterBody2D:
			var hitPlayerID = str(body.name).to_int()
			if GameManager.Players.has(hitPlayerID):
				if body.hasPower:
					return
				body.activatePowerUp(shootSpeed, moveSpeed, healthChange)
				playerAffected = body
				playerAffected.hasPower = true
				visible = false
				$Timer.start()
				pickedUp = true
				$PickupSound.play()


func _on_timer_timeout() -> void:
	GameManager.Powerups.erase(self)
	if spawnedSpot == null:
		print("Spawned Spot Null")
		return
	spawnedSpot.hasItem = false
	playerAffected.activatePowerUp(.6, 75, 0)
	playerAffected.hasPower = false
	queue_free()
