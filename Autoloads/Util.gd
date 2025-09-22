extends Node

signal scene_changed(path : String, scene : Node)

func getRandomName() -> String:
	var cons : String = "bcdfghjklmnpqrstvwxz"
	var vows : String = "aeiou"
	return cons[randi() % cons.length()] + vows[randi() % vows.length()] + cons[randi() % cons.length()]

func changeSceneToFileButDoesntSUCK_ASS(path : String) -> Node:
	#Caching values
	var tree = get_tree()
	var newScene : Node = load(path).instantiate()
	var oldScene = tree.current_scene
	
	#Changing scene
	tree.root.remove_child(oldScene)
	tree.root.add_child(newScene)
	tree.current_scene = newScene
	oldScene.queue_free()
	
	scene_changed.emit(path, newScene)
	
	return newScene
