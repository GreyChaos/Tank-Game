extends Control

var Address
var peer
var currentScene

@export var port = 8910

var mapChoice = GameManager.MAPS[0]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	GameManager.switchMaps.connect(switchMaps)
	load_player_settings()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$CountScreen/Countdown.text = "Starting in: " + "%0.1f" % $CountScreen/Timer.time_left


# Server And Client
func peer_connected(id):
	print("Player Connected " + str(id))


# Server And Client
func peer_disconnected(id):
	print("Player Disconnected " + str(id))


# Client
func connected_to_server():
	print("Connected")
	SendPlayerInfo.rpc_id(1, $CustomizeScreen/CustomizeMenu/Name.text, multiplayer.get_unique_id(), $CustomizeScreen/CustomizeMenu/Tank1.modulate)


# Client
func connection_failed():
	print("Connection Failed")


@rpc("any_peer", "reliable")
func SendPlayerInfo(name, id, custom_color: Color):
	GameManager.Players[id] = {
		"name": name,
		"id": id,
		"wasWinner": false,
		"playerObject": null,
		"color": custom_color,
		"hat": 0
	}
	var listText = "Players"
	for player in GameManager.Players:
		listText += ("\n" + GameManager.Players[player].name)
	$"Player List".text = listText

	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInfo.rpc(GameManager.Players[i].name, i, GameManager.Players[i].color)


@rpc("any_peer", "call_local", "reliable")
func StartGame(mapPath: String):
	if currentScene != null:
		currentScene.queue_free()
	$CountScreen/Timer.start()
	$CountScreen.visible = true
	mapChoice = mapPath
	
	
@rpc("any_peer", "call_local", "reliable")
func ContinueGame(mapPath: String):
	mapChoice = mapPath
	if is_instance_valid(currentScene):
		for player in currentScene.get_children():
			if player.has_node("MultiplayerSynchronizer"):
				player.get_node("MultiplayerSynchronizer").public_visibility = false
		currentScene.queue_free()
		currentScene = null
	await get_tree().process_frame
	_on_start_timer_timeout()
	


func _on_start_button_down() -> void:
	$ButtonClicked.play()
	StartGame.rpc(mapChoice)


func _on_join_button_down() -> void:
	$ButtonClicked.play()
	peer = ENetMultiplayerPeer.new()
	peer.create_client($JoinScreen/Server.text, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	save_player_settings()
	$"Player List".visible = true
	$JoinScreen/Server.editable = false
	$JoinScreen/Join.visible = false
	$JoinScreen/Back.visible = false

func _on_host_button_down() -> void:
	$ButtonClicked.play()
	peer = ENetMultiplayerPeer.new()

	var error = peer.create_server(port, 8)
	if error != OK:
		print("Cant Host: " + error)
		return

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

	SendPlayerInfo($CustomizeScreen/CustomizeMenu/Name.text, multiplayer.get_unique_id(), $CustomizeScreen/CustomizeMenu/Tank1.modulate)

	$"Player List".visible = true
	$HostScreen/Start.visible = true
	$HostScreen/Host.visible = false
	$HostScreen/Back.visible = false

func _on_join_menu_button_down() -> void:
	$ButtonClicked.play()
	$StartScreen.visible = false
	$JoinScreen.visible = true


func _on_host_menu_button_down() -> void:
	$ButtonClicked.play()
	$StartScreen.visible = false
	$HostScreen.visible = true


func _on_map_1_button_down() -> void:
	$ButtonClicked.play()
	mapChoice = GameManager.MAPS[0]
	$HostScreen/MapSelected.global_position = $HostScreen/Map1.global_position

func _on_map_2_button_down() -> void:
	$ButtonClicked.play()
	mapChoice = GameManager.MAPS[1]
	$HostScreen/MapSelected.global_position = $HostScreen/Map2.global_position
	
func _on_map_3_button_down() -> void:
	$ButtonClicked.play()
	mapChoice = GameManager.MAPS[2]
	$HostScreen/MapSelected.global_position = $HostScreen/Map3.global_position

func _on_map_4_button_down() -> void:
	$ButtonClicked.play()
	mapChoice = GameManager.MAPS[3]
	$HostScreen/MapSelected.global_position = $HostScreen/Map4.global_position
	
	
func _on_map_5_button_down() -> void:
	$ButtonClicked.play()
	mapChoice = GameManager.MAPS[4]
	$HostScreen/MapSelected.global_position = $HostScreen/Map5.global_position

	
func _on_settings_button_down() -> void:
	$ButtonClicked.play()
	$StartScreen.visible = false
	$SettingsScreen.visible = true


func _on_exit_button_down() -> void:
	get_tree().quit()


func _on_name_text_changed(new_text: String) -> void:
	save_player_settings()
	if multiplayer.is_server():
		SendPlayerInfo(new_text, multiplayer.get_unique_id(), $CustomizeScreen/CustomizeMenu/Tank1.modulate)
	else:
		SendPlayerInfo.rpc_id(1, new_text, multiplayer.get_unique_id(), $CustomizeScreen/CustomizeMenu/Tank1.modulate)


func _on_start_timer_timeout() -> void:
	var cam = get_node_or_null("Camera2D")
	if is_instance_valid(cam):
		cam.queue_free()
	$Music.stop()
	self.hide()
	if multiplayer.is_server():
		currentScene = load(mapChoice).instantiate()
		currentScene.name = mapChoice.get_file().get_basename()
		$MapContainer.add_child(currentScene)
	
func switchMaps(mapPath: String) -> void:
	ContinueGame.rpc(mapPath)


func _on_customize_menu_button_down() -> void:
	$ButtonClicked.play()
	$CustomizeScreen/CustomizeMenu/ColorPicker.visible = !$CustomizeScreen/CustomizeMenu/ColorPicker.is_visible_in_tree()

func _on_color_picker_color_changed(color: Color) -> void:
	save_player_settings()
	if multiplayer.is_server():
		SendPlayerInfo($CustomizeScreen/CustomizeMenu/Name.text, multiplayer.get_unique_id(), color)
	else:
		SendPlayerInfo.rpc_id(1, $CustomizeScreen/CustomizeMenu/Name.text, multiplayer.get_unique_id(), color)
	$CustomizeScreen/CustomizeMenu/Tank1.modulate = color
	
func save_player_settings():
	var config = ConfigFile.new()
	# Values Saved
	config.set_value("player", "name", $CustomizeScreen/CustomizeMenu/Name.text)
	config.set_value("player", "color", $CustomizeScreen/CustomizeMenu/Tank1.modulate.to_html())
	config.set_value("server", "last connected", $JoinScreen/Server.text)
	config.set_value("setting", "audio master", $"SettingsScreen/MasterVolume/Master Volume".value)
	config.set_value("setting", "fullscreen", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

	config.save("user://settings.cfg")
	
func load_player_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		# Load name
		var saved_name = config.get_value("player", "name", "Default Name")
		$CustomizeScreen/CustomizeMenu/Name.text = saved_name
		# Load color
		var saved_color_hex = config.get_value("player", "color", "#ffffff")
		$CustomizeScreen/CustomizeMenu/Tank1.modulate = Color.html(saved_color_hex)
		# Load last IP
		var last_ip =  config.get_value("server", "last connected", "127.0.0.1")
		$JoinScreen/Server.text = last_ip
		# Load Volume
		var saved_master_volume =  config.get_value("setting", "audio master", "0")
		$"SettingsScreen/MasterVolume/Master Volume".value = float(saved_master_volume)
		# Load Fullscreen
		var saved_fullscreen =  config.get_value("setting", "fullscreen", false)
		if saved_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)

func _on_back_button_down() -> void:
	$ButtonClicked.play()
	$StartScreen.visible = true
	$JoinScreen.visible = false
	$HostScreen.visible = false
	$SettingsScreen.visible = false


func _on_h_slider_value_changed(value: float) -> void:
	save_player_settings()
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), value)


func _on_toggle_fullscreen_button_down() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	save_player_settings()
