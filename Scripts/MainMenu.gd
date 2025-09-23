extends Node

@onready var menuHolder : Control = $MenuHolder
@onready var playHolder : Control = $PlayHolder
@onready var loadButtonHolder : Control = $PlayHolder/VBoxContainer/LoadHolder

####################################################################################################

func onPlayPressed():
	menuHolder.hide()
	playHolder.show()
	loadButtonHolder.visible = FileIO.getSaveExists()

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
