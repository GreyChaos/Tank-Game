extends Node2D

var avalible_ice_sections = []
var current_breaking_ice_index = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	avalible_ice_sections = get_children()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_cracking_timer_timeout() -> void:
	if multiplayer.is_server():
		if current_breaking_ice_index == null:
			current_breaking_ice_index = randi_range(0, avalible_ice_sections.size()-1)
			if avalible_ice_sections[current_breaking_ice_index].is_broken:
				current_breaking_ice_index = null
				return
			crack_ice.rpc(current_breaking_ice_index)
		crack_ice.rpc(current_breaking_ice_index)

@rpc("any_peer", "call_local", "reliable")
func crack_ice(ice_to_break_index: int):
	avalible_ice_sections[ice_to_break_index].crack_ice()
	
