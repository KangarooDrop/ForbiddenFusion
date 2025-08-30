extends Node

func onPlayPressed():
	get_tree().change_scene_to_file(Preloader.mainPath)

func onMultiplayerPressed() -> void:
	get_tree().change_scene_to_file(Preloader.multiplayerPath)

func onCollectionPressed():
	get_tree().change_scene_to_file(Preloader.deckEditorPath)

func onSettingsPressed():
	pass

func onExitPressed():
	get_tree().quit(0)
