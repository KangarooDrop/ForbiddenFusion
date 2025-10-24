extends Node

class_name AudioManager

var deafened : bool = false
var volume : float = 0.5
var streamPlayers : Array = []

func setDeafened(newDeafened : bool):
	self.deafened = newDeafened
	updateStreamPlayers()

func setVolume(newVolume : float):
	self.volume = newVolume
	updateStreamPlayers()

func updateStreamPlayers():
	var adjustedDB : float = getAudjustedDB()
	for asp : AudioStreamPlayer in streamPlayers:
		asp.volume_db = adjustedDB

func getAudjustedDB() -> float:
	return linear_to_db(volume if not deafened else 0.0)

func createAudioStreamPlayer(audioStream : AudioStream, pitch : float = 1.0, sigma : float = 0.0) -> AudioStreamPlayer:
	var asp : AudioStreamPlayer = AudioStreamPlayer.new()
	asp.finished.connect(self.onPlayerFinished.bind(asp))
	asp.stream = audioStream
	asp.volume_db = getAudjustedDB()
	
	asp.pitch_scale = pitch + randf_range(-sigma, sigma)
	
	add_child(asp)
	asp.play()
	
	streamPlayers.append(asp)
	
	return asp

func onPlayerFinished(asp : AudioStreamPlayer) -> void:
	clearStreamPlayer(asp)

func clearStreamPlayer(asp : AudioStreamPlayer):
	streamPlayers.erase(asp)
	asp.queue_free()

func clearAll():
	for i in range(streamPlayers.size()-1, -1, -1):
		streamPlayers[i].queue_free()
	streamPlayers.clear()
