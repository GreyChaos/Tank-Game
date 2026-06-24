extends Node2D

const SPEED = 200.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.cleanShells.connect(cleanShells)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	position += Vector2.UP.rotated(rotation) * SPEED * delta


func _on_area_2d_body_entered(_body: Node2D) -> void:
	queue_free()

func cleanShells() -> void:
	queue_free()

func _on_player_hit_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		var hitPlayerID = str(body.name).to_int()
		if GameManager.Players.has(hitPlayerID):
			var playerName = GameManager.Players[hitPlayerID].name
			body.takeDamage(hitPlayerID)
	queue_free()
