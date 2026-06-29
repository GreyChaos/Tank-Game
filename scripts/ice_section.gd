extends Node2D
class_name ice_section

var break_amount = 0
var is_broken = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func crack_ice():
	break_amount += 1
	if is_broken:
		return
	if break_amount >= 7:
		is_broken = true
		$StaticBody2D.collision_layer |= (1 << (4 - 1))
		$"..".current_breaking_ice_index = null
		$Mask/Texture.frame += 1
		for body in $Area2D.get_overlapping_areas():
			if body.get_parent() is CharacterBody2D:
				if body.has_method("cpu_deal_damage"):
					body.cpu_deal_damage(10)
				elif body.get_parent() is PlayerTank:
					body.get_parent().deal_damage(str(body.get_parent().name).to_int(), 10)
			else:
				body.get_parent().queue_free()
	else:
		$Mask/Texture.frame += 1
