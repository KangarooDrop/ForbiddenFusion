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

func setBodyType(newBodyType : int) -> void:
	bodyType = newBodyType
	bodySprite.region_rect.position.x = newBodyType * 40.0
func setHeadType(newHeadType : int) -> void:
	headType = newHeadType
	headSprite.region_rect.position.x = newHeadType * 40.0
func setEyeType(newEyeType : int) -> void:
	eyeType = newEyeType
	eyeSprite.region_rect.position.x = newEyeType * 40.0
func setMouthType(newMouthType : int) -> void:
	mouthType = newMouthType
	mouthSprite.region_rect.position.x = newMouthType * 40.0
func setArmType(newArmType : int) -> void:
	armType = newArmType
	armSprite.region_rect.position.x = newArmType * 40.0
func setFlipped(newFlipped : bool) -> void:
	if flipped != newFlipped:
		scale.x *= -1.0
	flipped = newFlipped

func randomize():
	setBodyType(randi() % 8)
	setHeadType(randi() % 8)
	setEyeType(randi() % 8)
	setMouthType(randi() % 8)
	setArmType(randi() % 8)
	setFlipped(randi() % 2 == 0)

func serialize() -> Dictionary:
	var rtn : Dictionary = {}
	rtn['body_type'] = bodyType
	rtn['head_type'] = headType
	rtn['eye_type'] = eyeType
	rtn['mouth_type'] = mouthType
	rtn['arm_type'] = armType
	rtn['flipped'] = flipped
	return rtn

func deserialize(data : Dictionary) -> void:
	setBodyType(data['body_type'])
	setHeadType(data['head_type'])
	setEyeType(data['eye_type'])
	setMouthType(data['mouth_type'])
	setArmType(data['arm_type'])
	setFlipped(data['flipped'])
