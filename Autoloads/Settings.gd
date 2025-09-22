extends Node

const defaultSettings : Dictionary = {
	BRIGHTNESS_KEY : 1.0,
	VSYNC_KEY : true,
	
	SOUND_VOLUME_KEY : 0.5,
	MUSIC_VOLUME_KEY : 0.5,
}

const BRIGHTNESS_KEY : String = "brightness"
const VSYNC_KEY : String = "vsync"

const SOUND_VOLUME_KEY : String = "sound_volume"
const SOUND_MUTED_KEY : String = "sound_muted"
const MUSIC_VOLUME_KEY : String = "music_volume"
const MUSIC_MUTED_KEY : String = "music_muted"

var settings : Dictionary = {}

@onready var dimmer : ColorRect = $CanvasLayer/Center/Scaler/Dimmer


#Tabs and pages
@onready var settingsNode : Control = $CanvasLayer/Center/Scaler/SettingsNode
@onready var tabsInactive : Control = settingsNode.get_node("TabsInactive")
@onready var tabsActive : Control = settingsNode.get_node("TabsActive")

@onready var videoTab : Control = tabsInactive.get_node("VideoTab")
@onready var audioTab : Control = tabsInactive.get_node("AudioTab")

@onready var pageHolder : Control = settingsNode.get_node("Background/Pages")
@onready var videoPage : Control = pageHolder.get_node("VideoPage")
@onready var audioPage : Control = pageHolder.get_node("AudioPage")

@onready var tabToPage : Dictionary = {
	videoTab : videoPage,
	audioTab : audioPage,
	
}

#Video setting nodes
@onready var brightnessSlider : HSlider = videoPage.get_node("VBoxContainer/BrightnessOption/HSlider")
@onready var vsynchButton : CheckBox = videoPage.get_node("VBoxContainer/VSyncOption/CheckBox")

#Audio setting nodes
@onready var musicVolumeSlider : HSlider = audioPage.get_node("VBoxContainer/MusicVolumeOption/HSlider")
@onready var musicMutedButton : CheckBox = audioPage.get_node("VBoxContainer/MusicMutedOption/CheckBox")
@onready var soundVolumeSlider : HSlider = audioPage.get_node("VBoxContainer/SoundVolumeOption/HSlider")
@onready var soundMutedButton : CheckBox = audioPage.get_node("VBoxContainer/SoundMutedOption/CheckBox")

func _ready() -> void:
	if not FileIO.getSaveExists():
		settings = defaultSettings.duplicate()
	else:
		settings = FileIO.getSettingsData()
	verifySettings()
	initSettingsNodes()
	onVideoTabPressed()

func verifySettings():
	var resaveSettings : bool = false
	for k in defaultSettings.keys():
		if not settings.has(k):
			settings[k] = defaultSettings[k]
			resaveSettings = true
	if resaveSettings:
		saveSettings()

func initSettingsNodes():
	#Video settings
	brightnessSlider.ratio = settings[BRIGHTNESS_KEY]
	setBrightness(brightnessSlider.ratio, false)
	vsynchButton.button_pressed = settings[VSYNC_KEY]
	setVSync(vsynchButton.button_pressed, false)
	
	#Audio settings
	musicVolumeSlider.ratio = settings[MUSIC_VOLUME_KEY]
	setMusicVolume(musicVolumeSlider.ratio, false)
	musicMutedButton.button_pressed = settings[MUSIC_MUTED_KEY]
	setMusicMuted(musicMutedButton.button_pressed, false)
	soundVolumeSlider.ratio = settings[SOUND_VOLUME_KEY]
	setSoundVolume(soundVolumeSlider.ratio, false)
	soundMutedButton.button_pressed = settings[SOUND_MUTED_KEY]
	setSoundMuted(soundMutedButton.button_pressed, false)

####################################################################################################

var currentTab = null
func setCurrentTab(newTab):
	if currentTab != null:
		currentTab.get_node("Background").color = Color(0.8, 0.8, 0.8, 1.0)
		currentTab.get_node("TextureButton").mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		tabsActive.remove_child(currentTab)
		tabsInactive.add_child(currentTab)
		tabToPage[currentTab].visible = false
	
	currentTab = newTab
	tabsInactive.remove_child(currentTab)
	tabsActive.add_child(currentTab)
	currentTab.get_node("Background").color = Color(1.0, 1.0, 1.0, 1.0)
	currentTab.get_node("TextureButton").mouse_default_cursor_shape = Control.CURSOR_ARROW
	tabToPage[currentTab].visible = true

func onVideoTabPressed() -> void:
	setCurrentTab(videoTab)

func onAudioTabPressed() -> void:
	setCurrentTab(audioTab)

####################################################################################################

func onBrightnessChange(_val = null):
	setBrightness(brightnessSlider.ratio, false)
func setBrightness(newBrightness : float, saveToSettings : bool = true):
	settings[BRIGHTNESS_KEY] = newBrightness
	if saveToSettings:
		saveSettings()
	dimmer.material.set_shader_parameter("brightness", newBrightness)

func onVSyncChange(_val = null):
	setVSync(vsynchButton.button_pressed)
func setVSync(newVSync : float, saveToSettings : bool = true):
	settings[VSYNC_KEY] = newVSync
	if saveToSettings:
		saveSettings()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if newVSync else DisplayServer.VSYNC_DISABLED)

####################################################################################################

func onMusicVolumeChange(_val = null):
	setMusicVolume(musicVolumeSlider.ratio, false)
func setMusicVolume(newMusicVolume : float, saveToSettings : bool = true):
	settings[MUSIC_VOLUME_KEY] = newMusicVolume
	if saveToSettings:
		saveSettings()
	MusicManager.volume = newMusicVolume
	MusicManager.updateStreamPlayers()

func onMusicMutedChange(_val = null):
	setMusicMuted(musicMutedButton.button_pressed)
func setMusicMuted(newMusicMuted : bool, saveToSettings : bool = true):
	settings[MUSIC_MUTED_KEY] = newMusicMuted
	if saveToSettings:
		saveSettings()
	MusicManager.deafened = newMusicMuted
	MusicManager.updateStreamPlayers()

func onSoundVolumeChange(_val = null):
	setSoundVolume(soundVolumeSlider.ratio, false)
func setSoundVolume(newSoundVolume : float, saveToSettings : bool = true):
	settings[SOUND_VOLUME_KEY] = newSoundVolume
	if saveToSettings:
		saveSettings()
	SoundManager.volume = newSoundVolume
	SoundManager.updateStreamPlayers()

func onSoundMutedChange(_val = null):
	setSoundMuted(soundMutedButton.button_pressed)
func setSoundMuted(newSoundMuted : bool, saveToSettings : bool = true):
	settings[SOUND_MUTED_KEY] = newSoundMuted
	if saveToSettings:
		saveSettings()
	SoundManager.deafened = newSoundMuted
	SoundManager.updateStreamPlayers()

func onSliderExit(_val = null):
	saveSettings()
func saveSettings():
	print("Saving to settings file.")
	FileIO.saveSettings(settings)

func showSettings():
	settingsNode.show()

func hideSettings():
	settingsNode.hide()

func isVisible() -> bool:
	return settingsNode.visible

func onClosePressed() -> void:
	hideSettings()
