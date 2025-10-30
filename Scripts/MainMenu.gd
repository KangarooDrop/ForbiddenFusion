extends Node

@onready var menuHolder : Control = $Center/MenuHolder
@onready var playHolder : Control = $Center/PlayHolder
@onready var loadButtonHolder : Control = $Center/PlayHolder/VBoxContainer/LoadHolder
@onready var savePreview : Node2D = $Center/PlayHolder/VBoxContainer/LoadHolder/Control/SavePreview

####################################################################################################

func onPlayPressed():
	menuHolder.hide()
	playHolder.show()
	loadButtonHolder.visible = FileIO.getSaveExists()
	if loadButtonHolder.visible:
		savePreview.setPlayerData()

func onMultiplayerPressed() -> void:
	Util.changeSceneToFileButDoesntSUCK_ASS(Preloader.multiplayerPath)

func onCollectionPressed():
	Util.changeSceneToFileButDoesntSUCK_ASS(Preloader.deckEditorPath)

func onSettingsPressed():
	Settings.showSettings()

func onExitPressed():
	get_tree().quit(0)

####################################################################################################

func onNewPressed():
	Util.changeSceneToFileButDoesntSUCK_ASS(Preloader.characterCreatorPath)

func onLoadPressed():
	Util.changeSceneToFileButDoesntSUCK_ASS(Preloader.rankingsPath)

func onBackPressed():
	menuHolder.show()
	playHolder.hide()
