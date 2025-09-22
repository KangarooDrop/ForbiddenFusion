extends AudioManager

const musicFallback : AudioStream = preload("res://Audio/Music/ScratchedAndMixed.mp3")
const musicMainMenu : AudioStream = preload("res://Audio/Music/ScratchedAndMixed.mp3")
const musicInGame : AudioStream = preload("res://Audio/Music/Nic-Silver-Reborn-in-a-Dream.mp3")

enum MUSIC_STATES {MAIN_MENU, RANKING, IN_GAME}
var currentState : MUSIC_STATES = -1

const stateToMusicGroups : Dictionary = {
	-1 : [musicFallback],
	MUSIC_STATES.MAIN_MENU : [musicMainMenu],
	MUSIC_STATES.RANKING : [musicInGame],
	MUSIC_STATES.IN_GAME : [musicInGame],
}

@onready var musicPlayer : AudioStreamPlayer = createAudioStreamPlayer(null)

func _ready() -> void:
	MusicManager.playMainMenu()
	Util.scene_changed.connect(self.onSceneChange)

func onSceneChange(path : String, newScene : Node):
	if path == Preloader.mainMenuPath:
		MusicManager.playMainMenu()
	elif path == Preloader.rankingsPath or path == Preloader.characterCreatorPath:
		MusicManager.playRanking()
	elif path == Preloader.mainPath:
		MusicManager.playInGame()

func playMusicStream(audioStream : AudioStream) -> void:
	if musicPlayer.stream == audioStream and musicPlayer.playing:
		return
	musicPlayer.stream = audioStream
	musicPlayer.play()

func refreshMusic():
	var musicGroup : Array = stateToMusicGroups[currentState]
	if musicGroup.is_empty():
		musicGroup = stateToMusicGroups[-1]
	var stream : AudioStream = musicGroup[randi() % musicGroup.size()]
	playMusicStream(stream)

func setState(newState):
	if newState == -1 or not stateToMusicGroups.has(newState) or currentState == newState:
		return
	currentState = newState
	refreshMusic()

func playMainMenu() -> void:
	setState(MUSIC_STATES.MAIN_MENU)

func playRanking() -> void:
	setState(MUSIC_STATES.RANKING)

func playInGame() -> void:
	setState(MUSIC_STATES.IN_GAME)

func onPlayerFinished(asp : AudioStreamPlayer) -> void:
	refreshMusic()


"""
extends AudioManager

var sampleBoards = \
[
	preload("res://Audio/Music/Nic-Silver-Reborn-in-a-Dream.mp3"),
	preload("res://Audio/Music/Canton_Floodwaters2-160.mp3"),
	preload("res://Audio/Music/Fluxx69_Head-Long-160.mp3"),
	preload("res://Audio/Music/LoopKitchen_ravenous130bpm-160.mp3"),
	preload("res://Audio/Music/TNH_The-Reason-Of-Techno-160.mp3"),
	preload("res://Audio/Music/Marco_Kalach-Synthetic_Fandango.mp3")
]

var sampleLobby = \
[
	preload("res://Audio/Music/marisameow_Soulful-Sunlight-160.mp3")
]

var sampleDeckEditor = \
[
	preload("res://Audio/Music/robbot-Z.mp3")
]

var sampleMenu = preload("res://Audio/Music/ScratchedAndMixed.mp3")

enum TRACKS {NONE, BOARD, MAIN_MENU, DECK_EDITOR, LOBBY}
var currentTrack : int = TRACKS.NONE

var fadeOutMaxTime = 1
var fadeOutRate = 60
var fadingTracks := {}

func playMainMenuMusic():
	if currentTrack != TRACKS.MAIN_MENU:
		currentTrack = TRACKS.NONE
		clearAll()
		createSoundEffect(sampleMenu)
		currentTrack = TRACKS.MAIN_MENU
	else:
		pass

func playDeckEditorMusic():
	if currentTrack != TRACKS.DECK_EDITOR:
		currentTrack = TRACKS.NONE
		clearAll()
		createSoundEffect(randomSoundEffect(sampleDeckEditor))
		currentTrack = TRACKS.DECK_EDITOR
	else:
		pass

func playBoardMusic():
	if currentTrack != TRACKS.BOARD:
		currentTrack = TRACKS.NONE
		clearAll()
		createSoundEffect(randomSoundEffect(sampleBoards))
		currentTrack = TRACKS.BOARD
	else:
		pass

func playLobbyMusic():
	if currentTrack != TRACKS.LOBBY:
		currentTrack = TRACKS.NONE
		clearAll()
		createSoundEffect(randomSoundEffect(sampleLobby))
		currentTrack = TRACKS.LOBBY
	else:
		pass

func clearAudioStreamPlayer(player : AudioStreamPlayer):
	fadeOut(player)
	
	
	if currentTrack == TRACKS.BOARD:
		currentTrack = TRACKS.NONE
		playBoardMusic()
	elif currentTrack == TRACKS.LOBBY:
		currentTrack = TRACKS.NONE
		playLobbyMusic()
	elif currentTrack == TRACKS.DECK_EDITOR:
		currentTrack = TRACKS.NONE
		playDeckEditorMusic()

func fadeOut(player : AudioStreamPlayer):
	fadingTracks[player] = fadeOutMaxTime

func _physics_process(delta):
	for ft in fadingTracks.keys():
		fadingTracks[ft] -= delta
		ft.volume_db -= fadeOutRate * delta
		if fadingTracks[ft] <= 0:
			.clearAudioStreamPlayer(ft)
			fadingTracks.erase(ft)


"""
