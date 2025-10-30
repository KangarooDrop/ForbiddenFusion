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

var cid : int = -1
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
		return RARITY.LEGENDARY

static func getCreatureTypeFromString(string : String) -> CREATURE_TYPE:
	string = string.to_upper()
	if CREATURE_TYPE.has(string):
		return CREATURE_TYPE[string]
	else:
		return CREATURE_TYPE.NULL
func _init(data : Dictionary):
	deserialize(data)

func onDestroy():
	if not isDestroyed:
		isDestroyed = true
		emit_signal("destroyed")

static func isNULL(creatureTypesStatic : Array) -> bool:
	return creatureTypesStatic.has(CREATURE_TYPE.NULL)
static func isOnlyNULL(creatureTypesStatic : Array) -> bool:
	return isNULL(creatureTypesStatic) and creatureTypesStatic.size() == 1
static func isNotNULL(creatureTypesStatic : Array) -> bool:
	return not isNULL(creatureTypesStatic)
static func isDualNotNULL(creatureTypesStatic : Array) -> bool:
	return isNotNULL(creatureTypesStatic) and creatureTypesStatic.size() == 2
static func getPercentNULL(creatureTypesStatic : Array) -> float:
	if isNotNULL(creatureTypesStatic):
		return 0.0
	else:
		return 1.0/creatureTypesStatic.size()

static func getCreatureTypesToVal(creatureTypesStatic : Array) -> int:
	var vBase : int = int(pow(2.0, CREATURE_TYPE.size()))
	var v : int = 0
	if isOnlyNULL(creatureTypesStatic):
		v = 0
	elif isNULL(creatureTypesStatic):
		v = vBase
	elif isDualNotNULL(creatureTypesStatic):
		v = vBase*3
	else:
		v = vBase*2
	
	for ct : CREATURE_TYPE in creatureTypesStatic:
		v += int(pow(2.0, ct))
	return v

static func getSort(card0 : Card, card1 : Card) -> bool:
	var v0 : int = getCreatureTypesToVal(card0.creatureTypes)
	var v1 : int = getCreatureTypesToVal(card1.creatureTypes)
	if v0 != v1:
		return v0 < v1
	
	var bst0 : int = getBST(card0)
	var bst1 : int = getBST(card1)
	if bst0 != bst1:
		return bst0 < bst1
	
	if card0.name != card1.name:
		return card0.name < card1.name
	
	return true


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
	rtn["cid"] = cid
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
	if data.has("cid"):
		cid = data["cid"]
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

func _to_string() -> String:
	return "<" + name + ":" + str(attack) + "/" + str(health) + ":" + str(abs(get_instance_id())%100) + ">"
