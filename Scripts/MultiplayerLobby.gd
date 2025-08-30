extends Node

@onready var hostButton : Button = $Camera2D/LobbyUI/HostButton
@onready var closeServerButton : Button = $Camera2D/LobbyUI/CloseServerButton
@onready var startGameButton : Button = $Camera2D/LobbyUI/StartGameButton
@onready var disconnectButton : Button = $Camera2D/LobbyUI/DisconnectButton
@onready var mainMenuButton : Button = $Camera2D/LobbyUI/MainMenuButton
@onready var connectButton : Button = $Camera2D/LobbyUI/ConnectButton
@onready var messageVBox : VBoxContainer = $Camera2D/LobbyUI/MessagesVBox
@onready var playerVBox : VBoxContainer = $Camera2D/LobbyUI/PlayersVBox
@onready var messageLineEdit : LineEdit = $Camera2D/LobbyUI/MessageLineEdit
@onready var ipAddressLineEdit : LineEdit = $Camera2D/LobbyUI/IPAddressLineEdit

var userToLabel : Dictionary = {}

func onUserConnected(userData : Server.UserData):
	disconnectButton.text = "Disconnect"
	
	messageReceived("User " + userData.username + " (" + str(userData.userID) + ") connected!")
	
	var label : Label = Label.new()
	label.text = userData.username + " (" + str(userData.userID) + ")"
	playerVBox.add_child(label)
	userToLabel[userData] = label
	
	if userToLabel.size() > 1 and Server.host:
		startGameButton.disabled = false

func onUserDisconnected(userData : Server.UserData):
	messageReceived("User " + userData.username + "(" + str(userData.userID) + ") disconnected!")
	
	if userToLabel.has(userData):
		userToLabel[userData].queue_free()
		userToLabel.erase(userData)
	
	if userToLabel.size() <= 1:
		startGameButton.disabled = true

func connectServer():
	Server.connect("user_connected", self.onUserConnected)
	Server.connect("user_disconnected", self.onUserDisconnected)
	Server.connect("server_closed", self.onServerClosed)
	Server.lobby_chat_received.connect(self.messageReceived)
	Server.lobby_start_game_received.connect(self.startGameReceived)

func disconnectServer():
	Server.disconnect("user_connected", self.onUserConnected)
	Server.disconnect("user_disconnected", self.onUserDisconnected)
	Server.disconnect("server_closed", self.onServerClosed)
	Server.lobby_chat_received.disconnect(self.messageReceived)
	Server.lobby_start_game_received.disconnect(self.startGameReceived)

func onServerClosed():
	disconnectServer()
	
	for userData in userToLabel.keys():
		userToLabel[userData].queue_free()
		userToLabel.erase(userData)

func onHostPressed() -> void:
	connectServer()
	
	Server.createGame()
	
	hostButton.disabled = true
	closeServerButton.disabled = false
	
	connectButton.disabled = true
	mainMenuButton.disabled = true

func onCloseServerPressed() -> void:
	Server.closeGame()
	
	hostButton.disabled = false
	closeServerButton.disabled = true
	
	connectButton.disabled = false
	mainMenuButton.disabled = false

func onConnectPressed() -> void:
	connectServer()
	
	var ipAddress : String = "127.0.0.1"
	print(ipAddressLineEdit.text)
	if not ipAddressLineEdit.text.is_empty():
		ipAddress = ipAddressLineEdit.text
	Server.joinGame(ipAddress)
	
	connectButton.disabled = true
	disconnectButton.disabled = false
	disconnectButton.text = "Cancel"
	
	hostButton.disabled = true
	mainMenuButton.disabled = true

func onDisconnectPressed() -> void:
	Server.closeGame()
	
	connectButton.disabled = false
	disconnectButton.disabled = true
	
	hostButton.disabled = false
	mainMenuButton.disabled = false

func onMainMenuPressed() -> void:
	get_tree().change_scene_to_file(Preloader.mainMenuPath)

func onUsernameChange(text : String):
	Server.myUserData.username = text

func onSendMessagePressed(text : String = "") -> void:
	var message : String = Server.myUserData.username + ": " + messageLineEdit.text
	messageLineEdit.text = ""
	Server.sendLobbyChatMessage(message)
	messageReceived(message)

func messageReceived(message : String):
	var label : Label = Label.new()
	label.text = message
	messageVBox.add_child(label)

func onStartGamePressed() -> void:
	Server.sendLobbyStartGame()
	startGameReceived()

func startGameReceived():
	disconnectServer()
	get_tree().change_scene_to_file(Preloader.mainPath)
