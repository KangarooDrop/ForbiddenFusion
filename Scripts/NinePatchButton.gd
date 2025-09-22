@tool
extends NinePatchRect

class_name NinePatchButton

@export var text : String = "":
	set(newText):
		text = newText
		if not is_instance_valid(label):
			return
		if newText == "Press Me_":
			return
		label.text = text
		labelShadow.text = text
		updateButtonSize()

@export var fontSize : int = 6:
	set(newFontSize):
		fontSize = newFontSize
		if not is_instance_valid(label):
			return
		label.add_theme_font_size_override("font_size", newFontSize)
		labelShadow.add_theme_font_size_override("font_size", newFontSize)
		updateButtonSize()

@export var textBuffer : Vector2i = Vector2i(4, 2):
	set(newTextBuffer):
		textBuffer = newTextBuffer
		if not is_instance_valid(label):
			return
		updateButtonSize()

func updateButtonSize():
	label.size = Vector2.ZERO
	self.size.x = textBuffer.x*2 + label.size.x
	self.size.y = textBuffer.y*2 + label.size.y
	label.position = textBuffer

@export var textureNormal : Texture
@export var textureHover : Texture
@export var texturePressed : Texture
@export var textureDisabled : Texture

var pressing : bool = false
var hovering : bool = false
@export var disabled : bool = false : 
	set(val):
		var isDiff = val != disabled
		disabled = val
		if isDiff:
			setTexture()
		if button != null:
			button.disabled = disabled

@onready var button : Button = $Button
@onready var label : Label = $Label
@onready var labelShadow : Label = $Label/Label2

signal button_down()
signal button_up()
signal pressed()

func onButtonDown() -> void:
	pressing = true
	setTexture()
	emit_signal("button_down")

func onButtonUp() -> void:
	pressing = false
	setTexture()
	emit_signal("button_up")

func onPressed() -> void:
	emit_signal("pressed")

func onFocusEntered() -> void:
	hovering = true
	setTexture()

func onFocusExited() -> void:
	hovering = false
	setTexture()

func setTexture():
	if disabled:
		texture = textureDisabled
	elif pressing:
		texture = texturePressed
	elif hovering:
		texture = textureHover
	else:
		texture = textureNormal
