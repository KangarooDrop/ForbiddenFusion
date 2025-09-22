extends RefCounted

class_name Card

enum CREATURE_TYPE \
{
	NULL,
	FIRE, WATER, EARTH, AIR, 
	BEAST, MECH, NECRO, HOLY,
}
#AGGRESSION METER!:
# Beast 7/1 -> Fire -> Necro -> Air ->
# Robot -> Water -> Holy -> Earth 0/8
enum RARITY {BASIC, COMMON, RARE, LEGENDARY}

var UUID : int = -1
var name : String = "_no_name"
var texture : Texture
var attack : int = 0
var health : int = 0
var maxHealth : int = 0
var rarity : RARITY = RARITY.BASIC
var creatureTypes := []

var isDestroyed : bool = false

signal changed()
signal destroyed()

static func getRarityFromString(string : String) -> RARITY:
	string = string.to_upper()
	if RARITY.has(string):
		return RARITY[string]
	else:
		return -1

static func getCreatureTypeFromString(string : String) -> CREATURE_TYPE:
	string = string.to_upper()
	if CREATURE_TYPE.has(string):
		return CREATURE_TYPE[string]
	else:
		return -1

func _init(data : Dictionary):
	deserialize(data)

func onDestroy():
	if not isDestroyed:
		isDestroyed = true
		emit_signal("destroyed")

static func getCreatureTypeDist(creatureTypes0 : Array, creatureTypes1 : Array) -> int:
	var dist : int = 0
	for a in creatureTypes0:
		if not a in creatureTypes1 and not a == CREATURE_TYPE.NULL:
			dist += 1
	for b in creatureTypes1:
		if not b in creatureTypes0 and not b == CREATURE_TYPE.NULL:
			dist += 1
	return dist

static func getCreatureTypesShared(creatureTypes0 : Array, creatureTypes1 : Array) -> int:
	var numShared : int = 0
	for ct in creatureTypes0:
		if ct in creatureTypes1:
			numShared += 1
	return numShared

static func getCreatureTypeToColor(creatureType0) -> Color:
	if creatureType0 == CREATURE_TYPE.NULL:
		return Color.YELLOW
	elif creatureType0 == CREATURE_TYPE.BEAST:
		return Color.SANDY_BROWN
	elif creatureType0 == CREATURE_TYPE.AIR:
		return Color.LIGHT_GREEN
	elif creatureType0 == CREATURE_TYPE.HOLY:
		return Color.LIGHT_YELLOW
	elif creatureType0 == CREATURE_TYPE.WATER:
		return Color.BLUE
	elif creatureType0 == CREATURE_TYPE.MECH:
		return Color.SLATE_GRAY
	elif creatureType0 == CREATURE_TYPE.EARTH:
		return Color.SADDLE_BROWN
	elif creatureType0 == CREATURE_TYPE.NECRO:
		return Color.BLACK
	elif creatureType0 == CREATURE_TYPE.FIRE:
		return Color.RED
	else:
		return Color.WHITE

static func getBST(card : Card) -> int:
	return card.attack + card.health

func serialize() -> Dictionary:
	var rtn : Dictionary = {}
	rtn["UUID"] = UUID
	rtn["name"] = name
	#rtn["texture"] = texture
	rtn["texturePath"] = texture.resource_path
	rtn["attack"] = attack
	rtn["health"] = health
	rtn["maxHealth"] = maxHealth
	rtn["rarity"] = rarity
	rtn["creatureTypes"] = creatureTypes
	return rtn

func deserialize(data : Dictionary):
	if data.has("UUID"):
		UUID = data["UUID"]
	if data.has("name"):
		name = data["name"]
	if data.has("texturePath"):
		texture = load(data["texturePath"])
	if data.has("texture"):
		texture = data["texture"]
	if data.has("attack"):
		attack = data["attack"]
	if data.has("health"):
		health = data["health"]
	if data.has("maxHealth"):
		maxHealth = data["maxHealth"]
	elif data.has("health"):
		maxHealth = data["health"]
	if data.has("rarity"):
		rarity = data["rarity"]
	if data.has("creatureTypes"):
		creatureTypes = data["creatureTypes"]
	emit_signal("changed")

func duplicate(_deep = false):
	return get_script().new(serialize())
