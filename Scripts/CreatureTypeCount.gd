extends Node

@onready var sprite : Sprite2D = $Center/Sprite2D
@onready var label : Label = $Center/Label
@onready var labelBack : Label = $Center/Label/LabelBack

func setCount(count : int):
	label.text = str(count)
	labelBack.text = label.text

func setCreatureType(creatureType : Card.CREATURE_TYPE):
	sprite.region_rect.position.x = int(creatureType) * 8.0
