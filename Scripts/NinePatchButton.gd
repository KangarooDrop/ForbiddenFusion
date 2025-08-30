@tool
extends NinePatchRect

@export var text : String = "":
	set(newText):
		text = newText
		if not is_instance_valid(label):
			return
		if newText == "Press Me_":
			return
		label.text = text
		labelShadow.text = text
		label.size.x = 0
		self.size.x = textBuffer*2 + label.size.x
		label.position.x = textBuffer

@export var textureNormal : Texture
@export var textureHover : Texture
@export var texturePressed : Texture
@export var textureDisabled : Texture

@export var textBuffer : int = 4

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
