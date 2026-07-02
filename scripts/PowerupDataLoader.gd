extends Node

const POWERUPS_FOLDER = "res://powerups/resources/"
var powerup_List : Array[PowerupData] = []


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var dir = DirAccess.open(POWERUPS_FOLDER)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var cleaned_file_name = file_name.replace(".remap", "")
		var full_path = POWERUPS_FOLDER + cleaned_file_name
		var resource = load(full_path)
		powerup_List.append(resource)
		file_name = dir.get_next()
	dir.list_dir_end()
