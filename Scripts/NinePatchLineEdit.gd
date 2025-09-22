@tool
extends NinePatchRect

class_name NinePatchLineEdit

var hovering : bool = false
var writing : bool = false

@onready var lineEdit : LineEdit = $LineEdit

@export var placeHolder : String = "":
	set(newPlaceHolder):
		placeHolder = newPlaceHolder
		if not is_instance_valid(lineEdit):
			return
		lineEdit.placeholder_text = placeHolder

@export var fontSize : int = 6:
	set(newFontSize):
		fontSize = newFontSize
		if not is_instance_valid(lineEdit):
			return
		lineEdit.add_theme_font_size_override("font_size", newFontSize)

@export var disabled : bool = false:
	set(newDisabled):
		disabled = newDisabled
		if not is_instance_valid(lineEdit):
			return
		lineEdit.editable = not disabled
		setTexture()


@export var textureNormal : Texture
@export var textureHover : Texture
@export var textureWriting : Texture
@export var textureDisabled : Texture

signal text_changed()

func onTextChanged(text : String) -> void:
	emit_signal("text_changed")

func onMouseEntered():
	hovering = true
	setTexture()

func onMouseExited():
	hovering = false
	setTexture()

func onFocusEntered() -> void:
	writing = true
	setTexture()

func onFocusExited() -> void:
	writing = false
	setTexture()

func setTexture():
	if disabled:
		texture = textureDisabled
	elif writing:
		texture = textureWriting
	elif hovering:
		texture = textureHover
	else:
		texture = textureNormal
