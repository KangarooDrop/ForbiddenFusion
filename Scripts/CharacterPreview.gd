extends Node
class_name CharacterPreview

@export var textureOffset : int = 0
@export var isLeft : bool = true

@onready var button : Button = $NPRButton
@onready var textureRect : TextureRect = $NPRButton/TextureRect
@onready var arrowLeft : Control = $ArrowLeft
@onready var arrowRight : Control = $ArrowRight

func _ready() -> void:
	(textureRect.texture as AtlasTexture).region.position.y = textureOffset
	arrowLeft.visible = isLeft
	arrowRight.visible = not isLeft
