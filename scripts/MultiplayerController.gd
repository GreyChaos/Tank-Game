extends Control

var Address
var peer
var currentScene
signal server_data_received(data)
var gamemode_selected = 0

@export var port = 8910

var mapChoice = GameManager.MAPS[0]


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	GameManager.switchMaps.connect(switchMaps)
	GameManager.fade_to_black.connect(fade_to_black)
	load_player_settings()
	
	# Assign buttons to animations
	for button in get_tree().get_nodes_in_group("ui_buttons"):
		button.mouse_entered.connect(on_button_hover.bind(button))
		button.mouse_exited.connect(off_button_hover.bind(button))


func _physics_process(_delta: float) -> void:
	if !GameManager.game_in_progress:
		# Have tank face mouse
		$MainMenu/CustomizeScreen/Tank1.look_at(get_global_mouse_position())
		$MainMenu/CustomizeScreen/Tank1.rotate(deg_to_rad(90))
	if Input.is_action_just_pressed("disconnect") and GameManager.game_in_progress:
		if multiplayer.is_server():
			_on_cancel_button_down()
			$MainMenu/MapContainer.get_child(0).queue_free()
			$MainMenu.visible = true
			$MainMenu/Music.play()
			$MainMenu/CountScreen.visible = false
			GameManager.Players.clear()
			GameManager.DeadPlayers.clear()
			GameManager.game_in_progress = false
		else:
			disconnect_client.rpc()
			$MainMenu/JoinScreen/Disconnect.visible = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	$MainMenu/CountScreen/Countdown.text = "Starting in: " + "%0.1f" % $MainMenu/CountScreen/Timer.time_left


# Server And Client
func peer_connected(id):
	print("Player Connected " + str(id))


# Server And Client
func peer_disconnected(id):
	# The host disconnected or player asked to be kicked
	if id == 1:
		if GameManager.game_in_progress:
			$MainMenu.visible = true
			$MainMenu/Music.play()
			GameManager.game_in_progress = false
		multiplayer.multiplayer_peer = null
		$MainMenu/JoinScreen/JoinError.text = "Disconnected"
		$MainMenu/"Player List".visible = false
		$MainMenu/JoinScreen/Server.editable = true
		$MainMenu/JoinScreen/Join.visible = true
		$MainMenu/JoinScreen/Back.visible = true
		GameManager.Players.clear()
		GameManager.DeadPlayers.clear()
		$MainMenu/JoinScreen/Disconnect.visible = false
		$MainMenu/CountScreen.visible = false
		$MainMenu/CountScreen/Timer.stop()
	# The client disconnected
	print("Player Disconnected " + str(id))
	var listText = "Players"
	if multiplayer.is_server():
		if GameManager.Players.has(id):
			if GameManager.Players[id].playerObject != null:
				GameManager.Players[id].playerObject.queue_free()
		$MainMenu/"HostScreen/CPU Slider".tick_count = 8 - GameManager.Players.size()
		$MainMenu/"HostScreen/CPU Slider".max_value = 8 - GameManager.Players.size()
	if id in GameManager.Players:
		GameManager.Players.erase(id)
	for player in GameManager.Players:
		listText += ("\n" + GameManager.Players[player].name)
	$MainMenu/"Player List".text = listText

# Client
func connected_to_server():
	# Ask Server if its good to join
	request_data.rpc_id(1, 1)
	var is_game_started = await server_data_received
	if !is_game_started:
		SendPlayerInfo.rpc_id(1, $MainMenu/CustomizeScreen/Name.text, multiplayer.get_unique_id(), $MainMenu/CustomizeScreen/Tank1.modulate)
		$MainMenu/JoinScreen/JoinError.text = "Connected"
		$MainMenu/JoinScreen/Disconnect.visible = true
	else:
		multiplayer.multiplayer_peer = null
		$MainMenu/JoinScreen/JoinError.text = "Game Already Started"
		$MainMenu/"Player List".visible = false
		$MainMenu/JoinScreen/Server.editable = true
		$MainMenu/JoinScreen/Join.visible = true
		$MainMenu/JoinScreen/Back.visible = true


@rpc("any_peer")
func request_data(query_id: int):
	var sender_id = multiplayer.get_remote_sender_id()
	# Check if game is in progress, and can join
	var data
	if query_id == 1:
		data = GameManager.game_in_progress
	rpc_id(sender_id, "recieve_data_from_server", data)


@rpc("authority")
func recieve_data_from_server(data):
	server_data_received.emit(data)


# Client
func connection_failed():
	multiplayer.multiplayer_peer = null
	$MainMenu/JoinScreen/JoinError.text = "Connection Failed"
	$MainMenu/"Player List".visible = false
	$MainMenu/JoinScreen/Server.editable = true
	$MainMenu/JoinScreen/Join.visible = true
	$MainMenu/JoinScreen/Back.visible = true


@rpc("any_peer", "reliable")
func SendPlayerInfo(player_name, id, custom_color: Color):
	GameManager.Players[id] = {
		"name": player_name,
		"id": id,
		"wasWinner": false,
		"playerObject": null,
		"color": custom_color,
		"hat": 0
	}
	var listText = "Players"
	for player in GameManager.Players:
		listText += ("\n" + GameManager.Players[player].name)
	$MainMenu/"Player List".text = listText

	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInfo.rpc(GameManager.Players[i].name, i, GameManager.Players[i].color)
	$MainMenu/"HostScreen/CPU Slider".tick_count = 8 - GameManager.Players.size()
	$MainMenu/"HostScreen/CPU Slider".max_value = 8 - GameManager.Players.size()


@rpc("any_peer", "call_local", "reliable")
func StartGame(mapPath: String):
	var fade_to_black_tween = create_tween()
	fade_to_black_tween.tween_property($FadeToBlack, "modulate:a", 1.0, 2)
	fade_to_black_tween.tween_property($FadeToBlack, "modulate:a", 0.0, 3)
	$MainMenu/MapSpawner.spawn_path = "../MapContainer"
	if currentScene != null:
		currentScene.queue_free()
	$MainMenu/CountScreen/Timer.start()
	$MainMenu/CountScreen.visible = true
	GameManager.current_map = mapPath
	mapChoice = mapPath
	GameManager.game_in_progress = true
	
	
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
	
@rpc("authority", "reliable")
func server_shutting_down():
	multiplayer.multiplayer_peer = null
	$MainMenu/JoinScreen/JoinError.text = "Server Shutdown"
	$MainMenu/"Player List".visible = false
	$MainMenu/JoinScreen/Server.editable = true
	$MainMenu/JoinScreen/Join.visible = true
	$MainMenu/JoinScreen/Back.visible = true
	$MainMenu/JoinScreen/Disconnect.visible = false
	GameManager.Players.clear()
	GameManager.DeadPlayers.clear()
	$MainMenu.visible = true
	$MainMenu/Music.play()
	$MainMenu/CountScreen.visible = false


func _on_start_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	var gamemode_values = SceneManager.GameMode.values()
	var selected_mode: SceneManager.GameMode = gamemode_values[gamemode_selected]
	GameManager.change_game_mode.rpc(selected_mode)
	StartGame.rpc(mapChoice)


func _on_join_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	peer = ENetMultiplayerPeer.new()
	peer.create_client($MainMenu/JoinScreen/Server.text, port)
	peer.get_peer(1).set_timeout(0, 0, 5000)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	save_player_settings()
	$MainMenu/JoinScreen/JoinError.text = ""
	$MainMenu/"Player List".visible = true
	$MainMenu/JoinScreen/Server.editable = false
	$MainMenu/JoinScreen/Join.visible = false
	$MainMenu/JoinScreen/Back.visible = false

func _on_host_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	peer = ENetMultiplayerPeer.new()

	var error = peer.create_server(port, 8)
	if error != OK:
		print("Cant Host: " + str(error))
		return

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

	SendPlayerInfo($MainMenu/CustomizeScreen/Name.text, multiplayer.get_unique_id(), $MainMenu/CustomizeScreen/Tank1.modulate)

	$MainMenu/"Player List".visible = true
	$MainMenu/HostScreen/Start.visible = true
	$MainMenu/HostScreen/Host.visible = false
	$MainMenu/HostScreen/Back.visible = false
	$MainMenu/HostScreen/Cancel.visible = true

func _on_join_menu_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	$MainMenu/StartScreen.visible = false
	$MainMenu/JoinScreen.visible = true


func _on_host_menu_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	$MainMenu/StartScreen.visible = false
	$MainMenu/HostScreen.visible = true


func _on_map_1_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	mapChoice = GameManager.MAPS[0]
	$MainMenu/HostScreen/MapSelected.global_position = $MainMenu/HostScreen/Map1.global_position
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(0, true) # FFA
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(1, true) # CTF
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(2, false) # KOTH
	$MainMenu/HostScreen/GameModeOptions.select(2)
	gamemode_selected = 0

func _on_map_2_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	mapChoice = GameManager.MAPS[1]
	$MainMenu/HostScreen/MapSelected.global_position = $MainMenu/HostScreen/Map2.global_position
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(0, false) # FFA
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(1, true) # CTF
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(2, true) # KOTH
	$MainMenu/HostScreen/GameModeOptions.select(0)
	gamemode_selected = 0
	
func _on_map_3_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	mapChoice = GameManager.MAPS[2]
	$MainMenu/HostScreen/MapSelected.global_position = $MainMenu/HostScreen/Map3.global_position
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(0, false) # FFA
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(1, true) # CTF
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(2, true) # KOTH
	$MainMenu/HostScreen/GameModeOptions.select(0)
	gamemode_selected = 0

func _on_map_4_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	mapChoice = GameManager.MAPS[3]
	$MainMenu/HostScreen/MapSelected.global_position = $MainMenu/HostScreen/Map4.global_position
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(0, true) # FFA
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(1, false) # CTF
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(2, true) # KOTH
	$MainMenu/HostScreen/GameModeOptions.select(1)
	gamemode_selected = 1
	
	
func _on_map_5_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	mapChoice = GameManager.MAPS[4]
	$MainMenu/HostScreen/MapSelected.global_position = $MainMenu/HostScreen/Map5.global_position
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(0, false) # FFA
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(1, true) # CTF
	$MainMenu/HostScreen/GameModeOptions.set_item_disabled(2, true) # KOTH
	$MainMenu/HostScreen/GameModeOptions.select(0)
	gamemode_selected = 0

	
func _on_settings_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	$MainMenu/StartScreen.visible = false
	$MainMenu/SettingsScreen.visible = true


func _on_exit_button_down() -> void:
	get_tree().quit()


func _on_name_text_changed(new_text: String) -> void:
	save_player_settings()
	if multiplayer.is_server():
		SendPlayerInfo(new_text, multiplayer.get_unique_id(), $MainMenu/CustomizeScreen/Tank1.modulate)
	else:
		SendPlayerInfo.rpc_id(1, new_text, multiplayer.get_unique_id(), $MainMenu/CustomizeScreen/Tank1.modulate)


func _on_start_timer_timeout() -> void:
	$MainMenu/Music.stop()
	$MainMenu.visible = false
	if multiplayer.is_server():
		currentScene = load(mapChoice).instantiate()
		currentScene.name = mapChoice.get_file().get_basename()
		$MainMenu/MapContainer.add_child(currentScene)
	
func switchMaps(mapPath: String) -> void:
	ContinueGame.rpc(mapPath)


func _on_customize_menu_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	$MainMenu/CustomizeScreen/ColorPicker.visible = !$MainMenu/CustomizeScreen/ColorPicker.is_visible_in_tree()
	if $MainMenu/CustomizeScreen/ColorPicker.visible:
		$MainMenu/CustomizeScreen/CustomizeMenu.text = "Confirm"
	else:
		$MainMenu/CustomizeScreen/CustomizeMenu.text = "Change Color"

func _on_color_picker_color_changed(color: Color) -> void:
	save_player_settings()
	if multiplayer.is_server():
		SendPlayerInfo($MainMenu/CustomizeScreen/Name.text, multiplayer.get_unique_id(), color)
	else:
		SendPlayerInfo.rpc_id(1, $MainMenu/CustomizeScreen/Name.text, multiplayer.get_unique_id(), color)
	$MainMenu/CustomizeScreen/Tank1.modulate = color
	
func save_player_settings():
	var config = ConfigFile.new()
	# Values Saved
	config.set_value("player", "name", $MainMenu/CustomizeScreen/Name.text)
	config.set_value("player", "color", $MainMenu/CustomizeScreen/Tank1.modulate.to_html())
	config.set_value("server", "last connected", $MainMenu/JoinScreen/Server.text)
	config.set_value("setting", "audio master", $MainMenu/"SettingsScreen/MasterVolume/Master Volume".value)
	config.set_value("setting", "fullscreen", DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

	config.save("user://settings.cfg")
	
func load_player_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err == OK:
		# Load name
		var saved_name = config.get_value("player", "name", "Default Name")
		$MainMenu/CustomizeScreen/Name.text = saved_name
		# Load color
		var saved_color_hex = config.get_value("player", "color", "#ffffff")
		$MainMenu/CustomizeScreen/Tank1.modulate = Color.html(saved_color_hex)
		# Load last IP
		var last_ip =  config.get_value("server", "last connected", "127.0.0.1")
		$MainMenu/JoinScreen/Server.text = last_ip
		# Load Volume
		var saved_master_volume =  config.get_value("setting", "audio master", "0")
		$MainMenu/"SettingsScreen/MasterVolume/Master Volume".value = float(saved_master_volume)
		# Load Fullscreen
		var saved_fullscreen =  config.get_value("setting", "fullscreen", false)
		if saved_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)

func _on_back_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	$MainMenu/StartScreen.visible = true
	$MainMenu/JoinScreen.visible = false
	$MainMenu/HostScreen.visible = false
	$MainMenu/SettingsScreen.visible = false
	$MainMenu/JoinScreen/JoinError.text = ""
	


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


func _on_cpu_slider_value_changed(value: float) -> void:
	GameManager.CPU_count = value


func _on_cancel_button_down() -> void:
	GameManager.game_in_progress = false
	$MainMenu/CountScreen.visible = false
	$MainMenu/CountScreen/Timer.stop()
	server_shutting_down.rpc()
	multiplayer.multiplayer_peer.close()
	$MainMenu/ButtonClicked.play()
	multiplayer.multiplayer_peer = null
	$MainMenu/HostScreen/Cancel.visible = false
	$MainMenu/HostScreen/Back.visible = true
	$MainMenu/HostScreen/Start.visible = false 
	$MainMenu/HostScreen/Host.visible = true
	GameManager.Players.clear()
	GameManager.DeadPlayers.clear()
	$MainMenu/"Player List".visible = false


func _on_disconnect_button_down() -> void:
	$MainMenu/ButtonClicked.play()
	disconnect_client.rpc()
	$MainMenu/JoinScreen/Disconnect.visible = false

@rpc("any_peer", "reliable")
func disconnect_client():
	if multiplayer.is_server():
		multiplayer.multiplayer_peer.disconnect_peer(multiplayer.get_remote_sender_id())
		
func on_button_hover(button: Button):
	button.scale = button.scale * 1.05
	
func off_button_hover(button: Button):
	button.scale = button.scale / 1.05
	
func fade_to_black():
	var fade_to_black_tween = create_tween()
	fade_to_black_tween.tween_property($FadeToBlack, "modulate:a", 1.0, 5)
	fade_to_black_tween.tween_property($FadeToBlack, "modulate:a", 0.0, 3)
	pass


func _on_game_mode_options_item_selected(index: int) -> void:
	gamemode_selected = index
