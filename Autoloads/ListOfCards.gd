extends Node

const CARD_WIDTH : int = 48
const CARD_HEIGHT : int = 66
const CARD_SIZE : Vector2i = Vector2i(CARD_WIDTH, CARD_HEIGHT)

var creatureTypeImageList = [null, 
		preload("res://Art/types/type_null.png"), 
		preload("res://Art/types/type_fire.png"), 
		preload("res://Art/types/type_water.png"), 
		preload("res://Art/types/type_rock.png"), 
		preload("res://Art/types/type_beast.png"), 
		preload("res://Art/types/type_mech.png"),
		preload("res://Art/types/type_necro.png")]

var cardList : Array = []
var scriptToID : Dictionary = {}

const cardsPath : String = "res://Scripts/Data/CardLists/card_list.csv"

func _ready() -> void:
	readCardFile()

func readCardFile():
	var file = FileAccess.open(cardsPath, FileAccess.READ)
	var headers : Array = []
	while true:
		var csvLine = file.get_csv_line()
		if csvLine.size() <= 1:
			break
		if headers.is_empty():
			headers = csvLine
			continue
		
		var data : Dictionary = {}
		for i in range(headers.size()):
			var header : String = headers[i]
			var val = csvLine[i]
			if val.is_empty() or header.begins_with("#"):
				continue
			if header == "texturePath":
				val = "res://Art/portraits/" + val + ".png"
			elif header == "cid" or header == "attack" or header == "health":
				val = int(val)
			elif header == "rarity":
				val = Card.getRarityFromString(val)
			elif header == "creatureTypes":
				var ctypes : Array = []
				for ct in val.rsplit(';'):
					ct = Card.getCreatureTypeFromString(ct)
					if ct != -1:
						ctypes.append(ct)
				if ctypes.size() > 1 and ctypes[1] < ctypes[0]:
					var tmp = ctypes[0]
					ctypes[0] = ctypes[1]
					ctypes[1] = tmp
				val = ctypes
			data[header] = val
		
		var card : Card = createCard(data)
		addCard(card)

func addCard(card : Card):
	card.cid = cardList.size()
	cardList.append(card)

func createCard(data : Dictionary) -> Card:
	return Card.new(data)

func getCard(index : int):
	if index < 0 or index >= cardList.size():
		return null
	return cardList[index].duplicate()

func getRandomCard(properties : Dictionary = {}) -> Card:
	var cardOptions : Array = cardList.duplicate()
	return getCard(cardOptions[randi() % cardOptions.size()].cid)
