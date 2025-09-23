extends Node2D

var playerRankNodePacked : PackedScene = preload("res://Scenes/PlayerRankNode.tscn")

var playerRankNodes : Array = []
var uuidToRankNode : Dictionary = {}

var checkedSlam : bool = false
var movingFromGame : bool = false
var shouldSlam : bool = true
var canSelect : bool = false
var createUserRank : bool = false
var pause : float = 1.0
var firstPlaceSlamTimer : float = 0.0
const firstPlaceSlamMaxTime : float = 1.0
var waveSlamTimer : float = 0.0
const waveSlamTimePerPlayer : float = 0.04
var waveSlamMaxTime : float = 0.0

var lastOffset : float = 0.0

@onready var playerRankHolder : Node2D = $PlayerRankHolder
@onready var firstPlaceHolder : Node2D = $FirstPlaceHolder
@onready var firstPlaceNode : Control = $FirstPlaceHolder/FirstPlaceNode
@onready var cam : Camera2D = $Camera2D
@onready var pauseMenu : Control = $Camera2D/PauseMenu

var userRank : PlayerRankNode = null

func _ready() -> void:
	playerRankNodes.append(firstPlaceNode)
	firstPlaceNode.background_pressed.connect(onRankBackgroundPressed.bind(firstPlaceNode))
	firstPlaceNode.fight_pressed.connect(onFightPressed.bind(firstPlaceNode))
	moveCam(firstPlaceHolder.global_position)
	
	if FileIO.getSaveExists():
		onLoadFile()
	else:
		onNewFile()

func updateUUIDDict() -> void:
	for prn : PlayerRankNode in playerRankNodes:
		uuidToRankNode[prn.playerUUID] = prn

func onNewFile():
	clear()
	var numPlayersTotal : int = 100
	for i in range(numPlayersTotal-2):
		addPlayerRank()
	for i in range(playerRankNodes.size()):
		playerRankNodes[i].randomize()
		playerRankNodes[i].setPlayerRank(i+1)
	createUserRank = true
	onSlam()
	updateUUIDDict()

func onLoadFile():
	clear()
	if not loadFromFile():
		onNewFile()
		print("ERROR: Could not find save file to load.")
		return
		
	createUserRank = false
	moveCamY(userRank.global_position.y)

func onSlam():
	shouldSlam = true
	canSelect = false
	pause = 1.0
	firstPlaceSlamTimer = 0.0
	waveSlamTimer = 0.0
	waveSlamMaxTime = playerRankNodes.size() * waveSlamTimePerPlayer
	moveCam(firstPlaceHolder.global_position)

func onSlamFinished():
	if createUserRank:
		addUserRank()
		saveToFile()

####################################################################################################
#CAMERA MOVEMENT

var CAM_BOUNDS_Y : Vector2 = Vector2(0, 0)

func moveCamX(globalX : float) -> void:
	cam.global_position.x = globalX
func moveCamY(globalY : float) -> void:
	cam.global_position.y = max(CAM_BOUNDS_Y.x, min(CAM_BOUNDS_Y.y, globalY))
func moveCam(globalPos : Vector2) -> void:
	moveCamX(globalPos.x)
	moveCamY(globalPos.y)

func _unhandled_input(event: InputEvent) -> void:
	if not canSelect:
		return
	
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				moveCamY(cam.global_position.y-64.0)
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				moveCamY(cam.global_position.y+64.0)
	
	elif event is InputEventKey:
		if event.is_pressed() and not event.is_echo():
			if event.keycode == KEY_ESCAPE:
				if Settings.isVisible():
					Settings.hideSettings()
				else:
					pauseMenu.visible = not pauseMenu.visible

####################################################################################################
#ANIMATIONS

func _process(delta: float) -> void:
	if not checkedSlam:
		checkedSlam = true
		if not movingFromGame:
			onSlam()
		else:
			canSelect = true
			moveCamY(userRank.global_position.y)
			#moveCamY(playerRankNodes[playerRankNodes.find(userRank)-1].global_position.y)
	
	lastOffset = firstPlaceNode.size.y - firstPlaceNode.SHRUNK_HEIGHT_ONE
	for i in range(1, playerRankNodes.size()):
		var slamOffset : float = max(0.0, 4.0 - abs(waveSlamTimer/waveSlamMaxTime*playerRankNodes.size() - float(i)))/4.0 * 128.0
		if waveSlamTimer == 0.0 or waveSlamTimer >= waveSlamMaxTime or not shouldSlam:
			slamOffset = 0.0
		var d : float = 4.0
		playerRankNodes[i].position = lerp(Vector2(playerRankNodes[i].position.x, playerRankNodes[i].position.y), Vector2(-playerRankNodes[1].size.x/2.0, lastOffset + slamOffset), 8 * delta)
		lastOffset += playerRankNodes[i].size.y + 2.0
	CAM_BOUNDS_Y.y = max(0.0, lastOffset-80.0)
	moveCam(cam.global_position)
	
	if shouldSlam:
		if pause > 0:
			pause -= delta
		
		elif firstPlaceSlamTimer < firstPlaceSlamMaxTime:
			firstPlaceSlamTimer += delta
			var t : float = min(1.0, firstPlaceSlamTimer/firstPlaceSlamMaxTime)
			firstPlaceHolder.position.y = -6.7*t*t*(t-1) * -64.0
			moveCamY(firstPlaceNode.global_position.y/4.0)
		
		elif waveSlamTimer <= waveSlamMaxTime:
			waveSlamTimer += delta
			
			var t : float = waveSlamTimer / waveSlamMaxTime
			t = 4 * t * t * t if t < 0.5 else 1 - pow(-2 * t + 2, 3) / 2
			var userIndex : int = playerRankNodes.find(userRank)
			if userIndex == -1:
				userIndex = playerRankNodes.size()
			var index : int = min(playerRankNodes.size()-1, userIndex * t)
			if index > 0:
				moveCamY(lerp(cam.global_position.y, playerRankNodes[index].global_position.y + playerRankNodes[index].size.y/2.0, 10.0 * delta))
			
			if waveSlamTimer > waveSlamMaxTime:
				shouldSlam = false
				await get_tree().create_timer(1.0).timeout
				canSelect = true
				onSlamFinished()
	
	else:
		if canSelect and selectedNodes.size() == 0 and not pauseMenu.visible:
			var hovering : Array = []
			var expanded : Array = []
			for prn : PlayerRankNode in playerRankNodes:
				if prn.hovering:
					hovering.append(prn)
				if prn.expanded:
					expanded.append(prn)
			for prn in expanded:
				if not hovering.has(prn):
					prn.expanded = false
			for prn in hovering:
				prn.expanded = true

####################################################################################################
#SAVING AND LOADING GAME DATA

func serialize() -> Array:
	var rtn : Array = []
	var players : Array = []
	for prn : PlayerRankNode in playerRankNodes:
		rtn.append(prn.serialize())
	return rtn

func deserialize(data : Array):
	var d : int = data.size() - playerRankNodes.size()
	if d < 0:
		for i in range(-d):
			removePlayerRank(playerRankNodes.size()-1)
	elif d > 0:
		for i in range(d):
			addPlayerRank()
	for i in range(data.size()):
		playerRankNodes[i].deserialize(data[i])
		playerRankNodes[i].setPlayerRank(i+1)
		if playerRankNodes[i].isUser:
			userRank = playerRankNodes[i]
	updateUUIDDict()

func saveToFile():
	var error = FileIO.saveGame(serialize())
	if error != OK:
		print("ERROR: Could not save game to file.")
	else:
		print("Game Saved!")

func loadFromFile() -> bool:
	var saveData = FileIO.getSaveData()
	
	for i in range(saveData.size()):
		saveData[i]["player_data"]["head_type"] = int(saveData[i]["player_data"]["head_type"])
		saveData[i]["player_data"]["body_type"] = int(saveData[i]["player_data"]["body_type"])
		saveData[i]["player_data"]["eye_type"] = int(saveData[i]["player_data"]["eye_type"])
		saveData[i]["player_data"]["mouth_type"] = int(saveData[i]["player_data"]["mouth_type"])
		saveData[i]["player_data"]["arm_type"] = int(saveData[i]["player_data"]["arm_type"])
		saveData[i]["deck_data"] = DeckEditor.parseDeckJSON(saveData[i]["deck_data"])
	
	deserialize(saveData)
	return true

####################################################################################################
#USER OPTIONS

var selectedNodes : Array = []
func onRankBackgroundPressed(buttonIndex : int, prn : PlayerRankNode):
	if not canSelect:
		return
	if buttonIndex == MOUSE_BUTTON_LEFT:
		selectNode(prn)

func onFightPressed(prn : PlayerRankNode):
	#playGame(prn.deckData)
	#setPlayerRank(userRank, playerRankNodes.find(prn))
	#swapRanks(playerRankNodes.find(prn), playerRankNodes.find(userRank))
	
	var mainNode = Util.changeSceneToFileButDoesntSUCK_ASS(Preloader.mainPath)
	mainNode.boardNode.board.players[0].playerUUID = userRank.playerUUID
	mainNode.boardNode.board.players[1].playerUUID = prn.playerUUID
	
	mainNode.boardNode.board.players[0].deck.setData(DeckEditor.getSaveDeck(userRank.playerUUID))
	mainNode.boardNode.board.players[1].deck.setData(DeckEditor.getSaveDeck(prn.playerUUID))
	
	mainNode.boardNode.initDecksAndStart()

func onEditPressed(prn : PlayerRankNode):
	var deckEditor = Util.changeSceneToFileButDoesntSUCK_ASS(Preloader.deckEditorPath)
	var deckData : Dictionary = DeckEditor.getSaveDeck(prn.playerUUID)
	deckEditor.setDeckData(deckData)

func selectNode(prn : PlayerRankNode):
	if not selectedNodes.has(prn):
		selectedNodes.append(prn)
		prn.expanded = true
		prn.scale = Vector2.ONE*1.05
	else:
		selectedNodes.erase(prn)
		prn.expanded = false
		prn.scale = Vector2.ONE*1.00

####################################################################################################
#MANIPULATING RANK OBJECTS WITHIN GAME

func addPlayerRank(isUser : bool = false) -> PlayerRankNode:
	var prn : PlayerRankNode = playerRankNodePacked.instantiate()
	prn.isUser = isUser
	playerRankHolder.add_child(prn)
	prn.position.y = lastOffset
	#prn.position.x = 600
	lastOffset = prn.position.y + prn.size.y + 2.0
	CAM_BOUNDS_Y.y = max(0.0, lastOffset-80.0)
	prn.background_pressed.connect(onRankBackgroundPressed.bind(prn))
	prn.fight_pressed.connect(onFightPressed.bind(prn))
	prn.edit_pressed.connect(onEditPressed.bind(prn))
	prn.setPlayerRank(playerRankNodes.size()+1)
	playerRankNodes.append(prn)
	
	return prn

func addUserRank():
	userRank = addPlayerRank(true)
	userRank.randomize()
	userRank.position.x = -600
	
	var userDataDictionary = FileIO.getUserData()
	userRank.setPlayerName(userDataDictionary['player_name'])
	userRank.getPlayerPortrait().deserialize(userDataDictionary['player_data'])
	#selectNode(userRank)

func removePlayerRank(index : int):
	if index < 0 or index >= playerRankNodes.size():
		return
	var prn : PlayerRankNode = playerRankNodes[index]
	prn.queue_free()
	playerRankNodes.remove_at(index)

func clear():
	#IGNORES THE FIRST PLACE NODE
	for i in range(playerRankNodes.size()-1, 0, -1):
		removePlayerRank(i)
	shouldSlam = false
	userRank = null
	lastOffset = 0.0

func swapRanks(index0 : int, index1 : int):
	if index0 > index1:
		swapRanks(index1, index0)
		return
	if index0 == 0:
		var frn : PlayerRankNode = playerRankNodes[index0]
		var prn : PlayerRankNode = playerRankNodes[index1]
		if frn == userRank:
			userRank = prn
		elif prn == userRank:
			userRank = frn
		var tmp : Dictionary = frn.serialize()
		frn.deserialize(prn.serialize())
		uuidToRankNode[frn.playerUUID] = frn
		uuidToRankNode[prn.playerUUID] = prn
		prn.deserialize(tmp)
	else:
		var prn0 : PlayerRankNode = playerRankNodes[index0]
		var prn1 : PlayerRankNode = playerRankNodes[index1]
		prn0.setPlayerRank(index1+1)
		prn1.setPlayerRank(index0+1)
		var tmp : PlayerRankNode = prn0
		playerRankNodes[index0] = playerRankNodes[index1]
		playerRankNodes[index1] = tmp

func setPlayerRank(prn : PlayerRankNode, newIndex : int):
	if newIndex == 0:
		setPlayerRank(prn, 1)
		swapRanks(0, 1)
	else:
		var oldIndex : int = playerRankNodes.find(prn)
		playerRankNodes.remove_at(oldIndex)
		playerRankNodes.insert(newIndex, prn)
		for i in range(min(oldIndex, newIndex), max(oldIndex, newIndex)+1):
			playerRankNodes[i].setPlayerRank(i+1)

####################################################################################################
#DEBUG FUNCS TO BE KILLED

func onSavePressed() -> void:
	pass

func onNewPressed() -> void:
	onNewFile()
	#onSavePressed()

func onLoadFromEmptyPressed() -> void:
	onLoadFile()
	onSlam()

func onLoadFromGamePressed() -> void:
	onLoadFile()
	canSelect = true

####################################################################################################
#PAUSE MENU FUNCS

func onResumePressed() -> void:
	pauseMenu.hide()

func onSettingsPressed() -> void:
	Settings.showSettings()

func onMainMenuPressed() -> void:
	saveToFile()
	Util.changeSceneToFileButDoesntSUCK_ASS(Preloader.mainMenuPath)
