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

	pass # Replace with function body.


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
	SendPlayerInfo.rpc_id(1, $JoinScreen/Name.text, multiplayer.get_unique_id())


# Client
func connection_failed():
	print("Connection Failed")


@rpc("any_peer", "reliable")
func SendPlayerInfo(name, id):
	GameManager.Players[id] = {
		"name": name,
		"id": id,
		"wasWinner": false,
		"playerObject": null,
		"color": Color(randf(), randf(), randf())
	}
	var listText = "Players"
	for player in GameManager.Players:
		listText += ("\n" + GameManager.Players[player].name)
	$"Player List".text = listText

	if multiplayer.is_server():
		for i in GameManager.Players:
			SendPlayerInfo.rpc(GameManager.Players[i].name, i)


@rpc("any_peer", "call_local", "reliable")
func StartGame(mapPath: String):
	if currentScene != null:
		currentScene.queue_free()
	$CountScreen/Timer.start()
	$CountScreen.visible = true
	mapChoice = mapPath
	
	
@rpc("any_peer", "call_local", "reliable")
func ContinueGame(mapPath: String):
	if currentScene != null:
		currentScene.queue_free()
	_on_start_timer_timeout()
	mapChoice = mapPath


func _on_start_button_down() -> void:
	StartGame.rpc(mapChoice)


func _on_join_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	peer.create_client($JoinScreen/Server.text, port)
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

	$"Player List".visible = true
	$JoinScreen/Server.editable = false
	$JoinScreen/Join.visible = false


func _on_host_button_down() -> void:
	peer = ENetMultiplayerPeer.new()

	var error = peer.create_server(port, 8)
	if error != OK:
		print("Cant Host: " + error)
		return

	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)

	SendPlayerInfo($HostScreen/Name.text, multiplayer.get_unique_id())

	$"Player List".visible = true
	$HostScreen/Start.visible = true
	$HostScreen/Host.visible = false


func _on_join_menu_button_down() -> void:
	$StartScreen.visible = false
	$JoinScreen.visible = true


func _on_host_menu_button_down() -> void:
	$StartScreen.visible = false
	$HostScreen.visible = true


func _on_map_1_button_down() -> void:
	mapChoice = GameManager.MAPS[0]
	$HostScreen/MapSelected.global_position = $HostScreen/Map1.global_position

func _on_map_2_button_down() -> void:
	mapChoice = GameManager.MAPS[1]
	$HostScreen/MapSelected.global_position = $HostScreen/Map2.global_position
	
func _on_map_3_button_down() -> void:
	mapChoice = GameManager.MAPS[2]
	$HostScreen/MapSelected.global_position = $HostScreen/Map3.global_position

func _on_map_4_button_down() -> void:
	mapChoice = GameManager.MAPS[3]
	$HostScreen/MapSelected.global_position = $HostScreen/Map4.global_position
	
func _on_settings_button_down() -> void:
	$StartScreen/Settings.text = "Coming Soon!"


func _on_exit_button_down() -> void:
	get_tree().quit()


func _on_name_text_changed(new_text: String) -> void:
	if multiplayer.is_server():
		SendPlayerInfo(new_text, multiplayer.get_unique_id())
	else:
		SendPlayerInfo.rpc_id(1, new_text, multiplayer.get_unique_id())


func _on_start_timer_timeout() -> void:
	if $Camera2D != null:
		$Camera2D.queue_free()
	$Music.stop()
	currentScene = load(mapChoice).instantiate()
	get_tree().root.add_child(currentScene)
	self.hide()
	
func switchMaps(mapPath: String) -> void:
	ContinueGame.rpc(mapPath)
