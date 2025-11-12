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

####################################################################################################

var basicsArray : Array = []
func getAllBasics() -> Array:
	if basicsArray.is_empty():
		for card : Card in cardList:
			if card.rarity == Card.RARITY.BASIC:
				basicsArray.append(card)
	return basicsArray

func getCardWeight(card : Card, deckParams : Dictionary) -> float:
	if Card.isNULL(card.creatureTypes):
		return deckParams[DECK_MUL_NULL]
	elif Card.isDualNotNULL(card.creatureTypes):
		return deckParams[DECK_MUL_DUAL]
	else:
		return 1.0

const DECK_MUL_NULL : String = "mul_null"
const DECK_MUL_DUAL : String = "mul_dual"
const DECK_MUL_COMP : String = "mul_comp"
const DEFAULT_DECK_PARAMS : Dictionary = \
{
	DECK_MUL_NULL : 0.0,
	DECK_MUL_DUAL : 0.0,
	DECK_MUL_COMP : 0.0,
}

func genStartDeckData(deckParams : Dictionary) -> Dictionary[int, int]:
	for k in DEFAULT_DECK_PARAMS.keys():
		if not deckParams.has(k):
			deckParams[k] = DEFAULT_DECK_PARAMS[k]
	
	var deckData : Dictionary[int, int] = {}
	var valWeights : Dictionary = {}
	for card : Card in getAllBasics():
		valWeights[card.cid] = getCardWeight(card, deckParams)
	
	for i in range(30):
		var cidToAdd : int = Util.getWeightedRand(valWeights)
		var cardToAdd : Card = ListOfCards.cardList[cidToAdd]
		for possibleCID : int in valWeights.keys():
			var possibleCard : Card = ListOfCards.cardList[possibleCID]
			var wAdded : float = 1.0
			var canFuse : bool = FusionManager.getFusion(cardToAdd, possibleCard) >= 0
			if Card.isNULL(possibleCard.creatureTypes):
				wAdded = deckParams[DECK_MUL_NULL]
				if canFuse:
					wAdded = min(1.0, wAdded * 20)
			else:
				if not canFuse:
					wAdded -= deckParams[DECK_MUL_COMP]
				if Card.isDualNotNULL(possibleCard.creatureTypes):
					wAdded *= deckParams[DECK_MUL_DUAL]
			
			"""
			if Card.isNULL(possibleCard.creatureTypes):
				wAdded = deckParams[DECK_MUL_NULL]
			else:
				if FusionManager.getFusion(cardToAdd, possibleCard) >= 0:
					wAdded = 1.0
				else:
					wAdded = 1.0-deckParams[DECK_MUL_COMP]
				if Card.isDualNotNULL(possibleCard.creatureTypes):
					wAdded *= deckParams[DECK_MUL_DUAL]
			"""
			valWeights[possibleCID] += wAdded
			
		if not deckData.has(cidToAdd):
			deckData[cidToAdd] = 0
		deckData[cidToAdd] += 1
	#print(valWeights)
	
	return deckData
