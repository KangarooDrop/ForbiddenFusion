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
	boardNode.move_camera.connect(self.onBoardMoveCamera)
	boardNode.game_end.connect(self.onGameEnd)
	onBoardMoveCamera(1 if boardNode.board.activePlayer == boardNode.board.players[0] else -1)
	
	if Server.online:
		Server.board_sync_board.connect(receiveSyncBoard)
		Server.board_card_node_pressed.connect(receiveCardNodePressed)
		Server.board_turn_passed.connect(receiveTurnPassed)
		Server.board_opponent_disconnected.connect(receiveOpponentDisconnected)
		Server.board_opponent_conceded.connect(receiveOpponentConcede)
	
	if Server.online and Server.host:
		syncBoard()

func onGameEnd():
	await get_tree().create_timer(3.0).timeout
	var winnerRank : int = boardNode.winner.playerRank
	var loserRank : int = boardNode.board.getOpponent(boardNode.winner).playerRank
	
	var rankingsNode = Util.changeSceneToFileButDoesntSUCK_ASS(Preloader.rankingsPath)
	rankingsNode.movingFromGame = true
	
	var winnerRankNode : PlayerRankNode = rankingsNode.playerRankNodes[winnerRank-1]
	var loserRankNode : PlayerRankNode = rankingsNode.playerRankNodes[loserRank-1]
	print("Winner: ", winnerRankNode.playerRank, " Loser:", loserRankNode.playerRank)
	if winnerRankNode.playerRank < loserRankNode.playerRank:
		print("Winner is higher than loser")
		if loserRankNode.playerRank < rankingsNode.playerRankNodes.size():
			print("PUNISHING LOSER!")
			rankingsNode.setPlayerRank(loserRankNode, loserRankNode.playerRank+1-1)
		else:
			print("You are too weak!")
	else:
		print("Moving up in the world.")
		rankingsNode.setPlayerRank(winnerRankNode, loserRankNode.playerRank-1)
	rankingsNode.saveToFile()

func _exit_tree() -> void:
	if Server.online:
		Server.board_sync_board.disconnect(receiveSyncBoard)
		Server.board_card_node_pressed.disconnect(receiveCardNodePressed)
		Server.board_turn_passed.disconnect(receiveTurnPassed)
		Server.board_opponent_conceded.disconnect(receiveOpponentConcede)
		Server.closeGame()

var lastCamOffset : int = 0
func onBoardMoveCamera(offset : int):
	if camDir == lastCamOffset:
		camDir = offset
	lastCamOffset = offset

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

func receiveTurnPassed():
	boardNode.board.turnEnd()

func receiveOpponentConcede():
	boardNode.board.players[1].loseGame(true)

func receiveOpponentDisconnected(userData : Server.UserData):
	receiveOpponentConcede()
	Server.closeGame()

func onCamUp():
	if camDir > -1:
		camDir -= 1
func onCamDown():
	if camDir < 1:
		camDir += 1

func onEscapePressed() -> void:
	if Settings.isVisible():
		Settings.hideSettings()
	else:
		pauseMenu.visible = not pauseMenu.visible

func _input(event: InputEvent) -> void:
	if boardNode.gameIsOver:
		return
	
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			onEscapePressed()
		elif event.keycode == KEY_SPACE:
			boardNode.playerPassTurn()
		
		elif event.keycode == KEY_Q:
			boardNode.playBestFusion()
		elif event.keycode == KEY_1:
			boardNode.onPlayerGameLoss(boardNode.board.players[1])
		elif event.keycode == KEY_2:
			boardNode.onPlayerGameLoss(boardNode.board.players[0])
	elif not pauseMenu.visible:
		if event is InputEventMouseButton and event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				onCamUp()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				onCamDown()
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				boardNode.returningFusionCards = true

func _process(delta: float) -> void:
	cam.position.y = lerp(cam.position.y, camDir * CAM_MOVE_DIST, 8.0 * delta)
	cam.zoom = lerp(cam.zoom, 4.0 * Vector2(1.0 + abs(camDir) * CAM_ZOOM_INC, 1.0 + abs(camDir) * CAM_ZOOM_INC), 8.0 * delta)

func onResumePressed() -> void:
	pauseMenu.hide()

func onSettingsPressed() -> void:
	Settings.showSettings()

func onConcedePressed() -> void:
	boardNode.board.players[0].loseGame(true)
	onResumePressed()

func onMainMenuPressed() -> void:
	Util.changeSceneToFileButDoesntSUCK_ASS(Preloader.mainMenuPath)
