extends Node

signal scene_changed(path : String, scene : Node)

const INT_MAX : int = 9223372036854775807
const INT_MIN : int = -9223372036854775808

func getRandomName() -> String:
	var cons : String = "bcdfghjklmnpqrstvwxz"
	var vows : String = "aeiou"
	return cons[randi() % cons.length()] + vows[randi() % vows.length()] + cons[randi() % cons.length()]

func testUUIDs():
	for j in range(10):
		var currentUUIDs : Array = []
		for i in range(100_000):
			var uuid : int = getUUID()
			if currentUUIDs.has(uuid):
				print("Duplicate UUID found after ", i, " iterations w/ value of ", uuid)
			else:
				currentUUIDs.append(uuid)
		var wait : int = randi() % 4
		var wString : String = ""
		match wait:
			0: wString = " 1 frame"
			1: wString = " 0.1 seconds"
			2: wString = " 1 second"
			3: wString = "? No!"
		print("Test ", j, " Complete. Waiting", wString, ".")
		match wait:
			0: await get_tree().process_frame
			1: await get_tree().create_timer(0.1).timeout
			2: await get_tree().create_timer(1.0).timeout
			_: pass
		
	print("Finished with UUID Tests")

const UUID_BIT_MASK: int = 0b1111111111111111
#const UUID_TIME_MUL : int = 1_000_000
func getUUID() -> int:
	var unixTime : float = Time.get_unix_time_from_system()
	var unixComp : int = int(unixTime * 1000.0) % UUID_BIT_MASK
	var currentTime : int = Time.get_ticks_usec()
	var currComp : int = currentTime % UUID_BIT_MASK
	var randInt : int = randi() % UUID_BIT_MASK
	var randComp0 : int = unixComp ^ randInt
	var randComp1 : int = currComp ^ randInt
	var out : int = (randComp1 << 16) + randComp0
	#var out : int = (randComp1 << 24) + (randComp0 << 16) + (currComp << 8) + (unixComp)
	return out

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
	
	#Notifying scene change for MusicManager
	scene_changed.emit(path, newScene)
	
	return newScene
