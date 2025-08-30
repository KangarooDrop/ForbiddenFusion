extends Node

const CAM_MOVE_DIST : float = 80.0
const CAM_ZOOM_INC : float = 0.125

@onready var boardNode : BoardNode = $Board
@onready var cam : Camera2D = $Camera2D
var camDir : int = 0

@onready var pauseMenu : Control = $Camera2D/PauseMenu

func _ready() -> void:
	boardNode.card_node_pressed.connect(self.onCardNodePressed)
	boardNode.turn_passed.connect(self.onTurnPassed)
	
	if Server.online:
		Server.board_sync_board.connect(receiveSyncBoard)
		Server.board_card_node_pressed.connect(receiveCardNodePressed)
		Server.board_turn_passed.connect(receiveTurnPassed)
		Server.board_opponent_disconnected.connect(receiveOpponentDisconnected)
		Server.board_opponent_conceded.connect(receiveOpponentConcede)
	
	if Server.online and Server.host:
		syncBoard()

func _exit_tree() -> void:
	if Server.online:
		Server.board_sync_board.disconnect(receiveSyncBoard)
		Server.board_card_node_pressed.disconnect(receiveCardNodePressed)
		Server.board_turn_passed.disconnect(receiveTurnPassed)
		Server.board_opponent_conceded.disconnect(receiveOpponentConcede)
		Server.closeGame()

func syncBoard():
	var data : Dictionary = boardNode.board.serialize()
	var tmp = data[0]
	data[0] = data[1]
	data[1] = tmp
	data["meta"]["activePlayer"] = (data["meta"]["activePlayer"]+1) % boardNode.board.players.size()
	Server.sendBoardSyncBoard(data)

func receiveSyncBoard(boardData : Dictionary):
	boardNode.board.deserialize(boardData)
	for i in range(boardNode.cardNodes.size()-1, -1, -1):
		var cardNode = boardNode.cardNodes[i]
		if not is_instance_valid(cardNode):
			boardNode.cardNodes.remove_at(i)
		elif not boardNode.cardNodeToZoneNode.has(cardNode):
			cardNode.queue_free()
			boardNode.cardNodes.remove_at(i)

func onCardNodePressed(cardNode, buttonIndex):
	if Server.online:
		var cardLocData : Array = Server.serializeCardNode(boardNode, cardNode)
		Server.sendBoardCardNodePressed(cardLocData, buttonIndex)

func receiveCardNodePressed(cardLocData : Array, buttonIndex : int):
	var cardNode : CardNode = Server.deserializeCardNode(boardNode, cardLocData)
	boardNode.onCardPressed(buttonIndex, cardNode, false)

func onTurnPassed():
	if Server.online:
		Server.sendBoardTurnPassed()

func  receiveTurnPassed():
	boardNode.board.turnEnd()

func receiveOpponentConcede():
	boardNode.board.players[1].loseGame(true)

func receiveOpponentDisconnected(userData : Server.UserData):
	receiveOpponentConcede()
	Server.closeGame()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_UP or event.keycode == KEY_W:
			if camDir > -1:
				camDir -= 1
		elif event.keycode == KEY_DOWN or event.keycode == KEY_S:
			if camDir < 1:
				camDir += 1
		
		elif event.keycode == KEY_ESCAPE:
			pauseMenu.visible = not pauseMenu.visible

func _process(delta: float) -> void:
	cam.position.y = lerp(cam.position.y, camDir * CAM_MOVE_DIST, 8.0 * delta)
	cam.zoom = lerp(cam.zoom, 4.0 * Vector2(1.0 + abs(camDir) * CAM_ZOOM_INC, 1.0 + abs(camDir) * CAM_ZOOM_INC), 8.0 * delta)

func onResumePressed() -> void:
	pauseMenu.hide()

func onSettingsPressed() -> void:
	pass # Replace with function body.

func onConcedePressed() -> void:
	boardNode.board.players[0].loseGame(true)
	onResumePressed()

func onMainMenuPressed() -> void:
	get_tree().change_scene_to_file(Preloader.mainMenuPath)
