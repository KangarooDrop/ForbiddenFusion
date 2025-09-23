extends Node2D

class_name PlayerPortrait

var bodyType : int = 0
var headType : int = 0
var eyeType : int = 0
var mouthType : int = 0
var armType : int = 0
var flipped : bool = false

@onready var bodySprite : Sprite2D = $BodySprite
@onready var headSprite : Sprite2D = $HeadSprite
@onready var eyeSprite : Sprite2D = $EyeSprite
@onready var mouthSprite : Sprite2D = $MouthSprite
@onready var armSprite : Sprite2D = $ArmSprite

const BODY_KEY : String = "body_type"
const HEAD_KEY : String = "head_type"
const EYE_KEY : String = "eye_type"
const MOUTH_KEY : String = "mouth_type"
const ARMS_KEY : String = "arm_type"
const FLIPPED_KEY : String = "flipped"

const NUM_BODY : int = 8
const NUM_HEAD : int = 8
const NUM_EYE : int = 8
const NUM_MOUTH : int = 8
const NUM_ARMS : int = 8

const SIZE : Vector2i = Vector2i(40, 40)

func setBodyType(newBodyType : int) -> void:
	bodyType = newBodyType
	bodySprite.region_rect.position.x = newBodyType * SIZE.x
func setHeadType(newHeadType : int) -> void:
	headType = newHeadType
	headSprite.region_rect.position.x = newHeadType * SIZE.x
func setEyeType(newEyeType : int) -> void:
	eyeType = newEyeType
	eyeSprite.region_rect.position.x = newEyeType * SIZE.x
func setMouthType(newMouthType : int) -> void:
	mouthType = newMouthType
	mouthSprite.region_rect.position.x = newMouthType * SIZE.x
func setArmType(newArmType : int) -> void:
	armType = newArmType
	armSprite.region_rect.position.x = newArmType * SIZE.x
func setFlipped(newFlipped : bool) -> void:
	if flipped != newFlipped:
		scale.x *= -1.0
	flipped = newFlipped

func randomize():
	deserialize(getRandomSerialized())

static func getRandomSerialized() -> Dictionary:
	var rtn : Dictionary = {}
	rtn[BODY_KEY] = randi() % NUM_BODY
	rtn[HEAD_KEY] = randi() % NUM_HEAD
	rtn[EYE_KEY] = randi() % NUM_EYE
	rtn[MOUTH_KEY] = randi() % NUM_MOUTH
	rtn[ARMS_KEY] = randi() % NUM_ARMS
	rtn[FLIPPED_KEY] = randi() % 2 == 0
	return rtn

func serialize() -> Dictionary:
	var rtn : Dictionary = {}
	rtn[BODY_KEY] = bodyType
	rtn[HEAD_KEY] = headType
	rtn[EYE_KEY] = eyeType
	rtn[MOUTH_KEY] = mouthType
	rtn[ARMS_KEY] = armType
	rtn[FLIPPED_KEY] = flipped
	return rtn

func deserialize(data : Dictionary) -> void:
	setBodyType(data[BODY_KEY])
	setHeadType(data[HEAD_KEY])
	setEyeType(data[EYE_KEY])
	setMouthType(data[MOUTH_KEY])
	setArmType(data[ARMS_KEY])
	setFlipped(data[FLIPPED_KEY])
