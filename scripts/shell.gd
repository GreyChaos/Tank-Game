extends Node2D

var speed = 200.0
var immune_to_objects = false
var fired_by

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	GameManager.cleanShells.connect(cleanShells)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	position += Vector2.UP.rotated(rotation) * speed * delta


func _on_area_2d_body_entered(_body: Node2D) -> void:
	if immune_to_objects:
		return
	queue_free()

func cleanShells() -> void:
	queue_free()

func _on_player_hit_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		if body == fired_by:
			return
		var hitPlayerID = str(body.name).to_int()
		if GameManager.Players.has(hitPlayerID):
			var playerName = GameManager.Players[hitPlayerID].name
			body.takeDamage(hitPlayerID)
	queue_free()
