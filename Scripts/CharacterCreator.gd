extends Node

@onready var playerPortrait : PlayerPortrait = $PlayerPortrait

@onready var headController : Control = $VBoxContainer/HeadController
@onready var bodyController : Control = $VBoxContainer/BodyController
@onready var eyeController : Control = $VBoxContainer/EyeController
@onready var mouthController : Control = $VBoxContainer/MouthController
@onready var armController : Control = $VBoxContainer/ArmController
@onready var nameNPLE : NinePatchLineEdit = $NameLineEdit

@onready var controllers : Array = [headController, bodyController, eyeController, mouthController, armController]
var controllerToPreviews : Dictionary = {}

func updatePreviews(controller):
	if not controllerToPreviews.has(controller):
		return
	var previews : Array = controllerToPreviews[controller]
	var currentIndex : int = -1
	if controller == headController:
		currentIndex = playerPortrait.headType
	elif controller == bodyController:
		currentIndex = playerPortrait.bodyType
	elif controller == eyeController:
		currentIndex = playerPortrait.eyeType
	elif controller == mouthController:
		currentIndex = playerPortrait.mouthType
	elif controller == armController:
		currentIndex = playerPortrait.armType
	var p0 : int = loopIndex(currentIndex - 1)
	var p1 : int = loopIndex(currentIndex + 1)
	previews[0].texture.region.position.x = p0 * 40.0
	previews[1].texture.region.position.x = p1 * 40.0

func _ready() -> void:
	for controller in controllers:
		var previews : Array = [controller.get_node("BetterButtonLeft/TextureRect"), controller.get_node("BetterButtonRight/TextureRect")]
		previews[0].get_parent().pressed.connect(self.onControllerPreviousPressed.bind(controller))
		previews[1].get_parent().pressed.connect(self.onControllerNextPressed.bind(controller))
		controllerToPreviews[controller] = previews
	onRandomPressed()

func loopIndex(index : int) -> int:
	return (index + 8) % 8

func onControllerPreviousPressed(controller) -> void:
	if controller == headController:
		playerPortrait.setHeadType(loopIndex(playerPortrait.headType-1))
	elif controller == bodyController:
		playerPortrait.setBodyType(loopIndex(playerPortrait.bodyType-1))
	elif controller == eyeController:
		playerPortrait.setEyeType(loopIndex(playerPortrait.eyeType-1))
	elif controller == mouthController:
		playerPortrait.setMouthType(loopIndex(playerPortrait.mouthType-1))
	elif controller == armController:
		playerPortrait.setArmType(loopIndex(playerPortrait.armType-1))
	updatePreviews(controller)

func onControllerNextPressed(controller) -> void:
	if controller == headController:
		playerPortrait.setHeadType(loopIndex(playerPortrait.headType+1))
	elif controller == bodyController:
		playerPortrait.setBodyType(loopIndex(playerPortrait.bodyType+1))
	elif controller == eyeController:
		playerPortrait.setEyeType(loopIndex(playerPortrait.eyeType+1))
	elif controller == mouthController:
		playerPortrait.setMouthType(loopIndex(playerPortrait.mouthType+1))
	elif controller == armController:
		playerPortrait.setArmType(loopIndex(playerPortrait.armType+1))
	updatePreviews(controller)

func onFlipPressed() -> void:
	playerPortrait.setFlipped(not playerPortrait.flipped)

func onRandomPressed() -> void:
	playerPortrait.randomize()
	nameNPLE.lineEdit.text = Util.getRandomName()
	for controller in controllers:
		updatePreviews(controller)

func getUserData() -> Dictionary:
	return {"player_name":nameNPLE.lineEdit.text, "player_data":playerPortrait.serialize()}

func onDonePressed() -> void:
	if nameNPLE.lineEdit.text.is_empty():
		nameNPLE.lineEdit.text = " "
	FileIO.deleteGame()
	FileIO.saveUserData(getUserData())
	Util.changeSceneToFileButDoesntSUCK_ASS(Preloader.rankingsPath)

func onBackPressed() -> void:
	Util.changeSceneToFileButDoesntSUCK_ASS(Preloader.mainMenuPath)
