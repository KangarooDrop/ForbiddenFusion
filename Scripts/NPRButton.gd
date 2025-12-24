extends Button

@onready var fontVariation : FontVariation = theme.get_font("font", "Button")
var isPressed : bool = false

#func isSizeBeingAnnoying() -> bool:
#	return true
#	return get_parent() is VBoxContainer or get_theme_font_size("font_size") > 6

func onButtonDown() -> void:
	if not isPressed:
		fontVariation.spacing_top = 1
		fontVariation.spacing_bottom = -1
		for c in get_children():
			c.position.y += 1
		isPressed = true

func onButtonUp() -> void:
	if isPressed:
		fontVariation.spacing_top = 0
		fontVariation.spacing_bottom = 0
		for c in get_children():
			c.position.y -= 1
		isPressed = false

func onMouseEnter() -> void:
	if button_pressed:
		onButtonDown()

func onMouseExit() -> void:
	if button_pressed:
		onButtonUp()
