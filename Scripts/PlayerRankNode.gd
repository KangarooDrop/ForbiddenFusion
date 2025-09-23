extends Control

class_name PlayerRankNode

var hovering : bool = false
var selecting : bool = false
var pressing : bool = false
var expanded : bool = false
var expandTimer : float = 0.0
const expandMaxTime : float = 0.125

const SHRUNK_HEIGHT : float = 16.0
const EXPAND_HEIGHT : float = 69.0

var playerName : String = "Robert Paulson"
var playerRank : int = -1
var playerUUID : int = -1
var deckData : Dictionary = {0:30}
var collection : Dictionary = {}
var isUser : bool = false

signal background_pressed(buttonIndex)
signal fight_pressed()
signal edit_pressed()

func getPlayerPortrait():
	return $ExtendedPage/PlayerPortrait

func getNameLabel() -> Label:
	return $Header/NameLabel

func getRankLabel() -> Label:
	return $Header/RankLabel

func getFightButton():
	return $ExtendedPage/FightButton

func getType0Sprite() -> Sprite2D:
	return $Type0Holder/Sprite2D
func getType1Sprite() -> Sprite2D:
	return $Type1Holder/Sprite2D

func getShrunkenHeight() -> float:
	return SHRUNK_HEIGHT
func getExpandHeight() -> float:
	return EXPAND_HEIGHT

func setTypeSprites():
	var ctDict : Dictionary = {}
	for ct in Card.CREATURE_TYPE.values():
		ctDict[ct] = 0
	for uuid in deckData.keys():
		var card : Card = ListOfCards.cardList[uuid]
		for ct in card.creatureTypes:
			ctDict[ct] += 1
	ctDict[Card.CREATURE_TYPE.NULL] *= 0.85
	var highest : int = -1
	var second : int = -1
	for ct in Card.CREATURE_TYPE.values():
		if highest == -1 or ctDict[ct]>ctDict[highest]:
			second = highest
			highest = ct
		elif second == -1 or ctDict[ct]>ctDict[second]:
			second = ct
	if second != -1 and ctDict[highest] > ctDict[second]*1.25:
		second = -1
	
	getType0Sprite().region_rect.position.x = highest * 8.0
	var type1Sprite : Sprite2D = getType1Sprite()
	if second == -1:
		type1Sprite.hide()
	else:
		type1Sprite.region_rect.position.x = second * 8.0
		type1Sprite.show()

func onMouseEnter():
	selecting = true

func onMouseExit():
	selecting = false

func _input(event: InputEvent) -> void:
	if not selecting and not pressing:
		return
	if not event is InputEventMouseButton:
		return
	
	if event.is_pressed():
		pressing = true
	elif pressing:
		pressing = false
		if selecting:
			background_pressed.emit(event.button_index)

func inBounds(globalPos : Vector2) -> bool:
	return globalPos.x > global_position.x and globalPos.x < global_position.x + size.x and globalPos.y > global_position.y and globalPos.y < global_position.y + size.y

func _process(delta: float) -> void:
	if expanded:
		if expandTimer < expandMaxTime:
			expandTimer = min(expandMaxTime, expandTimer+delta)
			size.y = lerp(getShrunkenHeight(), getExpandHeight(), expandTimer/expandMaxTime)
	else:
		if expandTimer > 0:
			expandTimer = max(0.0, expandTimer-delta)
			size.y = lerp(getShrunkenHeight(), getExpandHeight(), expandTimer/expandMaxTime)
	
	hovering = inBounds(get_global_mouse_position())

func onFightPressed():
	fight_pressed.emit()

func onEditPressed() -> void:
	edit_pressed.emit()




func randomize() -> void:
	var newPlayerName : String = Util.getRandomName()
	
	setPlayerName(newPlayerName)
	playerUUID = Util.getUUID()
	getPlayerPortrait().randomize()
	
	var validCards : Array = []
	var newDeckData : Dictionary = {}
	for index in ListOfCards.cardList.size():
		var card : Card = ListOfCards.cardList[index]
		if card.rarity == Card.RARITY.BASIC:
			validCards.append(card.duplicate())
	for i in range(30):
		var card : Card = validCards[randi() % validCards.size()]
		validCards.erase(card)
		newDeckData[card.UUID] = 1
	setDeckData(newDeckData)

func serialize() -> Dictionary:
	var rtn : Dictionary = {}
	rtn['player_name'] = playerName
	rtn['player_uuid'] = playerUUID
	rtn['player_data'] = getPlayerPortrait().serialize()
	rtn["is_user"] = isUser
	rtn['deck_data'] = deckData
	rtn['collection'] = collection
	return rtn

func setPlayerName(newPlayerName : String):
	self.playerName = newPlayerName
	getNameLabel().text = newPlayerName + ("" if not isUser else " (YOU)")
func setPlayerRank(newPlayerRank : int):
	self.playerRank = newPlayerRank
	getRankLabel().text = "#" + str(newPlayerRank)
func setDeckData(newDeckData : Dictionary):
	self.deckData = newDeckData
	setTypeSprites()
func setCollection(newCollection : Dictionary):
	self.collection = newCollection

func deserialize(data : Dictionary) -> void:
	isUser = data["is_user"]
	setPlayerName(data['player_name'])
	playerUUID = data['player_uuid']
	#setPlayerRank(data['player_rank'])
	getPlayerPortrait().deserialize(data['player_data'])
	setDeckData(data['deck_data'])
	setCollection(data['collection'])
