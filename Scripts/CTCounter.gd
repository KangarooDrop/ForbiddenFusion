extends Node

var creatureTypeCountPacked : PackedScene = preload("res://Scenes/CreatureTypeCount.tscn")

@onready var hbox : HBoxContainer = $HBoxContainer
@onready var label : Label = $Label

var creatureTypeToCounter : Dictionary = {}

func _ready() -> void:
	for ct in Card.CREATURE_TYPE.values():
		var counter = creatureTypeCountPacked.instantiate()
		hbox.add_child(counter)
		counter.setCreatureType(ct)
		creatureTypeToCounter[ct] = counter
	setLabelPos()

func setText(text : String) -> void:
	label.text = text
	label.visible = not text.is_empty()
	setLabelPos()

func setLabelPos() -> void:
	var sz : float = hbox.get_child_count() * hbox.get_theme_constant("separation")
	label.position.x = -sz/2.0 - label.size.x
	#Setting twice is required for some reason, do not remove
	label.position.x = -sz/2.0 - label.size.x

func setDeckData(deckData : Dictionary) -> void:
	setCreatureData(Util.getDeckDataToTypes(deckData))

func setCreatureData(creatureTypeData : Dictionary) -> void:
	for ct in creatureTypeData.keys():
		creatureTypeToCounter[ct].setCount(creatureTypeData[ct])
