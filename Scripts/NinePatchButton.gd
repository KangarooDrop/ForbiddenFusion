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
		for lab in labels:
			lab.text = text
		updateButtonSize()

@export var fontSize : int = 6:
	set(newFontSize):
		fontSize = newFontSize
		if not is_instance_valid(label):
			return
		for lab in labels:
			lab.add_theme_font_size_override("font_size", newFontSize)
		updateButtonSize()

@export var textBuffer : Vector2i = Vector2i(4, 2):
	set(newTextBuffer):
		textBuffer = newTextBuffer
		if not is_instance_valid(label):
			return
		updateButtonSize()

func updateButtonSize():
	label.size = Vector2.ZERO
	self.custom_minimum_size.x = textBuffer.x*2 + label.size.x
	self.custom_minimum_size.y = textBuffer.y*2 + label.size.y
	self.size = Vector2.ZERO
	label.position = textBuffer
	if get_parent() is VBoxContainer:
		label.position.x = (get_parent().size.x - label.size.x)/2.0

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
@onready var labelRight : Label = $Label/Label2
@onready var labelDown : Label = $Label/Label3
@onready var labels : Array = [label, labelRight, labelDown]

signal button_down()
signal button_up()
signal pressed()

func _ready() -> void:
	if is_instance_valid(label) and Engine.is_editor_hint():
		for lab in labels:
			if lab != label:
				if lab.text != label.text:
					lab.text = label.text
				if lab.get_theme_font_size("font_size") != label.get_theme_font_size("font_size"):
					lab.add_theme_font_size_override("font_size", label.get_theme_font_size("font_size"))

func onButtonDown() -> void:
	pressing = true
	label.position.y += 1
	setTexture()
	emit_signal("button_down")

func onButtonUp() -> void:
	pressing = false
	label.position.y -= 1
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
