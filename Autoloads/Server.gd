extends Node

class UserData:
	var username : String = "NO_NAME"
	var userID : int = -1
	
	func _init(data : Array) -> void:
		deserialize(data)
	
	func deserialize(data : Array):
		self.userID = data[0]
		self.username = data[1]
	
	func serialize() -> Array:
		return [userID, username]

var users : Dictionary = {}

var host = false
var online = false

var myUserData : UserData

const DEFAULT_SERVER_IP : String = "127.0.0.1"
const DEFAULT_PORT := 25565
const MAX_CONNECTIONS = 20

signal user_connected(userData : UserData)
signal user_disconnected(userData : UserData)
signal server_closed()

signal lobby_chat_received(message : String)
signal lobby_start_game_received()

signal board_sync_board(boardData : Dictionary)
signal board_card_node_pressed(cardLocData : Array, buttonIndex : int)
signal board_turn_passed()
signal board_opponent_disconnected(userData : UserData)
signal board_opponent_conceded()

func _ready():
	myUserData = UserData.new([0, "Username"])
	multiplayer.peer_connected.connect(onPlayerConnected)
	multiplayer.peer_disconnected.connect(onPlayerDisconnected)
	multiplayer.connected_to_server.connect(onConnectedOK)
	multiplayer.connection_failed.connect(onConnectedFail)
	multiplayer.server_disconnected.connect(onServerDisconnected)

####################################################################################################
### CALLED BY LOBBY TO CONNECT PLAYERS #############################################################
####################################################################################################

func createGame(port : int = -1):
	if online:
		print("Server: Could not create game while already connected.")
		return
	
	if port == -1:
		port = DEFAULT_PORT
	print("Server: Opening up port ", port)
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, MAX_CONNECTIONS)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	users[1] = myUserData
	onUserSet(myUserData)
	host = true
	online = true

func joinGame(address = "", port : int = -1):
	if online:
		print("Server: Could not join game while already connected.")
		return
	
	if address.is_empty():
		address = DEFAULT_SERVER_IP
	if port == -1:
		port = DEFAULT_PORT
	print("Server: Connecting to ", address, ":", port)
	
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error:
		return
	multiplayer.multiplayer_peer = peer
	host = false
	online = true

func closeGame():
	if online:
		print("Server: Closing connecting.")
		multiplayer.multiplayer_peer.close()
		online = false

func kick(id):
	multiplayer.multiplayer_peer.disconnect_peer(id, true)

#Called when a peer connects to the server
func onPlayerConnected(id : int):
	print("Server: User ", id, " Connected :)")
	setUserData.rpc_id(id, myUserData.serialize())

@rpc("any_peer", "reliable")
func setUserData(newUserData : Array):
	print("Server: Sending user data.")
	var userID : int = multiplayer.get_remote_sender_id()
	newUserData[0] = userID
	var newUser : UserData = UserData.new(newUserData)
	users[userID] = newUser
	print("Server: Received user data from ", userID, " : ", newUser.username)
	onUserSet(newUser)

func onUserSet(userData):
	user_connected.emit(userData)

#Called when a peer disconnects from the server
func onPlayerDisconnected(id : int):
	print("Server: User ", id, " Disconnected :(")
	user_disconnected.emit(users[id])
	board_opponent_disconnected.emit(users[id])
	users.erase(id)

#Called by/on host when a peer connects
func onConnectedOK():
	print("Server: Connected to host OK!")
	var peer_id = multiplayer.get_unique_id()
	myUserData.userID = peer_id
	users[peer_id] = myUserData
	onUserSet(myUserData)

#Called by/on host when a peer fails to connect
func onConnectedFail():
	print("Server: Could not connect to the host!")
	multiplayer.multiplayer_peer = null
	users.clear()
	online = false
	server_closed.emit()

#Called by/on peer when disconnected from the server
func onServerDisconnected():
	print("Server: Disconnected from the host!")
	multiplayer.multiplayer_peer = null
	users.clear()
	online = false
	server_closed.emit()

func sendLobbyChatMessage(message : String):
	onReceiveLobbyChatMessage.rpc(message)

@rpc("any_peer", "reliable")
func onReceiveLobbyChatMessage(message : String):
	lobby_chat_received.emit(message)

func sendLobbyStartGame():
	onReceiveLobbyStartGame.rpc()

@rpc("any_peer", "reliable")
func onReceiveLobbyStartGame():
	lobby_start_game_received.emit()
	print("Server: Start of game command received from host.")

#Chat message
#Starting game

####################################################################################################
### CALLED BY MAIN TO SYNC GAME STATES #############################################################
####################################################################################################

func sendBoardSyncBoard(boardData : Dictionary):
	onReceiveBoardSyncBoard.rpc(boardData)

@rpc("any_peer", "reliable")
func onReceiveBoardSyncBoard(boardData):
	board_sync_board.emit(boardData)
	print("Server: Received board data from host.")

func sendBoardCardNodePressed(cardLocData : Array, buttonIndex : int):
	onReceiveBoardCardNodePressed.rpc(cardLocData, buttonIndex)

@rpc("any_peer", "reliable")
func onReceiveBoardCardNodePressed(cardLocData : Array, buttonIndex : int):
	board_card_node_pressed.emit(cardLocData, buttonIndex)

static func serializeCardNode(boardNode : BoardNode, cardNode : CardNode) -> Array:
	var cardLocData : Array = []
	
	var isActivePlayers : bool = boardNode.cardNodeToZoneNode[cardNode].zone.player == boardNode.board.activePlayer
	var zoneIndex : int = -1
	var cardIndex : int = -1
	if boardNode.cardNodeToZoneNode[cardNode].zone is Hand:
		zoneIndex = 1
	elif boardNode.cardNodeToZoneNode[cardNode].zone is Deck:
		zoneIndex = 2
	elif boardNode.cardNodeToZoneNode[cardNode].zone is InPlayZone:
		cardIndex = boardNode.zoneToNode[boardNode.cardNodeToZoneNode[cardNode].zone].cardNodes.find(cardNode)
		zoneIndex = 3
	elif boardNode.cardNodeToZoneNode[cardNode].zone is FusionZone:
		zoneIndex = 4
	if cardIndex == -1:
		cardIndex = boardNode.cardNodeToZoneNode[cardNode].zone.cards.find(cardNode.card)
	return [isActivePlayers, zoneIndex, cardIndex]

static func deserializeCardNode(boardNode : BoardNode, cardLocData : Array) -> CardNode:
	var card : Card = null
	var cardNode : CardNode = null
	var player : Player = boardNode.board.activePlayer if cardLocData[0] else boardNode.board.getInactivePlayer()
	if cardLocData[1] == 1:
		card = player.hand.cards[cardLocData[2]]
	elif cardLocData[1] == 2:
		card = player.deck.cards[cardLocData[2]]
	elif cardLocData[1] == 3:
		return boardNode.zoneToNode[boardNode.board.getPlayerToInPlayZone(player)].cardNodes[cardLocData[2]]
	elif cardLocData[1] == 4:
		card = boardNode.board.getPlayerToFusionZone(player).cards[cardLocData[2]]
	if card == null:
		return null
	return boardNode.getCardNode(card)
	
func sendBoardTurnPassed():
	onReceiveBoardTurnPassed.rpc()

@rpc("any_peer", "reliable")
func onReceiveBoardTurnPassed():
	board_turn_passed.emit()
	
func sendBoardConcede():
	onReceiveBoardTurnPassed.rpc()

@rpc("any_peer", "reliable")
func onReceiveBoardConcede():
	board_opponent_conceded.emit()

#Chat message
#Loading decks
#Card clicked
#Turn passed
#Player concede/disconnect
