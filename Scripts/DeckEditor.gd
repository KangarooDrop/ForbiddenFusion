extends Node

class_name DeckEditor

@onready var cardNodeHolder : Node2D = $CardNodeHolder
@onready var deckLabel : Label = $DeckHolder/VBoxContainer/Label
@onready var deckVBox : VBoxContainer = $DeckHolder/VBoxContainer/ScrollContainer/VBoxContainer
@onready var deckCardButtonBase : Button = $DeckHolder/VBoxContainer/ScrollContainer/VBoxContainer/DeckCardButton
@onready var tfbHolder : Control = $FilterHolder/VBoxContainer/HBoxContainer/TFBHolder
@onready var nfbHolder1 : Control = $FilterHolder/VBoxContainer/HBoxContainer2/NFBHolder1
@onready var nfbHolder2 : Control = $FilterHolder/VBoxContainer/HBoxContainer2/NFBHolder2
@onready var nfbHolders : Array = [nfbHolder1, nfbHolder2]

@onready var noticeDialog : AcceptDialog = $Control/NoticeDialog
@onready var confirmDialog : ConfirmationDialog = $Control/ConfirmDialog
@onready var fileDialog : FileDialog = $Control/FileDialog

const WIDTH : int = 4
const HEIGHT : int = 2
const PAGE_SIZE : int = WIDTH*HEIGHT
const BUFFER : Vector2i = Vector2i(6, 24)
const CARD_OFFSET : Vector2 = ListOfCards.CARD_SIZE + BUFFER

var page : int = 0
var cards : Array = []
var cardNodes : Array = []

var playerUUID : int = -1
var collectionData : Dictionary = {}
var deckData : Dictionary = {}
var cidToButton : Dictionary = {}
var cidToCardNode : Dictionary = {}
var hasSaved : bool = false

func _ready() -> void:
	for i in range(Card.CREATURE_TYPE.size()):
		var newHolder : Control = tfbHolder.duplicate()
		tfbHolder.get_parent().add_child(newHolder)
		var tfb : TextureButton = newHolder.get_child(0)
		tfb.pressed.connect(self.onTypeFilterButtonPressed.bind(tfb, i))
		tfb.texture_normal = tfb.texture_normal.duplicate()
		tfb.texture_normal.region.position.x = i * 8
		newHolder.visible = true
		filters[FILTER_TYPE][i] = FILTER_VAL_NONE
	for i in range(nfbHolders.size()):
		var nfb : Control = nfbHolders[i].get_child(0)
		nfb.pressed.connect(self.onNumFilterButtonPressed.bind(nfb, i+1))
		filters[FILTER_NUM][i+1] = FILTER_VAL_NONE
	
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var cardNode : CardNode = Preloader.deckEditCardNodePacked.instantiate()
			cardNode.mouse_enter.connect(self.onCardMouseEnter.bind(cardNode))
			cardNode.mouse_exit.connect(self.onCardMouseExit.bind(cardNode))
			cardNode.button_down.connect(self.onCardButtonDown.bind(cardNode))
			cardNode.button_up.connect(self.onCardButtonUp.bind(cardNode))
			cardNode.pressed.connect(self.onCardPressed.bind(cardNode))
			cardNode.hide()
			cardNodeHolder.add_child(cardNode)
			var xoff : float = x - (WIDTH-1)/2.0
			var yoff : float = y - (HEIGHT-1)/2.0
			cardNode.position = Vector2(xoff, yoff) * CARD_OFFSET
			cardNodes.append(cardNode)
	setPage(0)
	setDeckText()

####################################################################################################
########## BUTTON PRESSING / USER INPUT ############################################################
####################################################################################################

var cardNodeHovering = null
var cardNodeSelected = null
func onCardMouseEnter(cardNode : CardNode):
	cardNode.showHovering = true
func onCardMouseExit(cardNode : CardNode):
	cardNode.showHovering = false
func onCardButtonDown(buttonIndex : int, cardNode : CardNode):
	if buttonIndex == MOUSE_BUTTON_LEFT:
		cardNode.showPressed = true
func onCardButtonUp(buttonIndex : int, cardNode : CardNode):
	if buttonIndex == MOUSE_BUTTON_LEFT:
		cardNode.showPressed = false
func onCardPressed(buttonIndex : int, cardNode : CardNode):
	if buttonIndex == MOUSE_BUTTON_LEFT:
		addCardToDeck(cardNode.card.cid)
	elif buttonIndex == MOUSE_BUTTON_RIGHT:
		removeCardFromDeck(cardNode.card.cid)

var lastMouseButtonIndex : int = -1
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_LEFT:
			if page > 0:
				setPage(page-1)
		elif event.keycode == KEY_RIGHT:
			if page < (cards.size()-1)/PAGE_SIZE:
				setPage(page+1)
	
		elif event.keycode == KEY_SPACE and true:
			clearDeck()
			var deckSize : int = 30
			for i in range(deckSize):
				var cardIndex : int = randi() % cards.size()
				addCardToDeck(cards[cardIndex].cid)
	
	elif event is InputEventMouseButton and event.is_released():
		lastMouseButtonIndex = event.button_index

const FILTER_VAL_NONE : int = 0
const FILTER_VAL_INCLUDE : int = 1
const FILTER_VAL_EXCLUDE : int = 2
const FILTER_TYPE : String = "f_type"
const FILTER_NUM : String = "f_num"
var filters : Dictionary = {FILTER_TYPE:{}, FILTER_NUM:{}}
func onTypeFilterButtonPressed(tfb : TextureButton, creatureType : int) -> void:
	var oldFilterVal : int = filters[FILTER_TYPE][creatureType]
	var newFilterVal : int = FILTER_VAL_INCLUDE if lastMouseButtonIndex == MOUSE_BUTTON_LEFT else FILTER_VAL_EXCLUDE
	if oldFilterVal == newFilterVal:
		filters[FILTER_TYPE][creatureType] = FILTER_VAL_NONE
	else:
		filters[FILTER_TYPE][creatureType] = newFilterVal
	
	var newColor : Color = Color.GRAY
	if filters[FILTER_TYPE][creatureType] == FILTER_VAL_INCLUDE:
		newColor = Color.WHITE
	elif filters[FILTER_TYPE][creatureType] == FILTER_VAL_EXCLUDE:
		newColor = Color.RED
	tfb.get_child(1).color = newColor
	
	updateFilters()

func onNumFilterButtonPressed(nfb : Button, numTypes : int) -> void:
	var oldFilterVal : int = filters[FILTER_NUM][numTypes]
	var newFilterVal : int = FILTER_VAL_INCLUDE if lastMouseButtonIndex == MOUSE_BUTTON_LEFT else FILTER_VAL_EXCLUDE
	if oldFilterVal == newFilterVal:
		filters[FILTER_NUM][numTypes] = FILTER_VAL_NONE
	else:
		filters[FILTER_NUM][numTypes] = newFilterVal
	
	var newColor : Color = Color.GRAY
	if filters[FILTER_NUM][numTypes] == FILTER_VAL_INCLUDE:
		newColor = Color.WHITE
	elif filters[FILTER_NUM][numTypes] == FILTER_VAL_EXCLUDE:
		newColor = Color.RED
	nfb.get_child(1).color = newColor
	
	updateFilters()

func updateFilters() -> void:
	cards = []
	for cid in collectionData.keys():
		var card : Card = ListOfCards.getCard(cid)
		var failed : bool = false
		for creatureType in filters[FILTER_TYPE].keys():
			if filters[FILTER_TYPE][creatureType] != FILTER_VAL_NONE:
				if filters[FILTER_TYPE][creatureType] == FILTER_VAL_INCLUDE and not card.creatureTypes.has(creatureType):
					failed = true
					break
				if filters[FILTER_TYPE][creatureType] == FILTER_VAL_EXCLUDE and card.creatureTypes.has(creatureType):
					failed = true
					break
		
		for numTypes in filters[FILTER_NUM].keys():
			if filters[FILTER_NUM][numTypes] != FILTER_VAL_NONE:
				if filters[FILTER_NUM][numTypes] == FILTER_VAL_INCLUDE and card.creatureTypes.size() != numTypes:
					failed = true
					break
				if filters[FILTER_NUM][numTypes] == FILTER_VAL_EXCLUDE and card.creatureTypes.size() == numTypes:
					failed = true
					break
		
		if not failed:
			cards.append(card)
			#print(Card.getCreatureTypesToVal(card.creatureTypes))
	cards.sort_custom(Card.getSort)
	setPage(0)

####################################################################################################
########## MANIPULATING DECK & COLLETION DATA ######################################################
####################################################################################################

func addCardToDeck(cid : int):
	if deckData.has(cid) and deckData[cid] >= collectionData[cid]:
		return
	
	if not deckData.has(cid):
		var deckCardButton = deckCardButtonBase.duplicate()
		deckCardButton.show()
		deckCardButton.connect("pressed", self.onDeckCardPressed.bind(cid))
		deckVBox.add_child(deckCardButton)
		deckData[cid] = 0
		cidToButton[cid] = deckCardButton
	deckData[cid] += 1
	cidToButton[cid].text = getDeckButtonText(cid, deckData[cid])
	if cidToCardNode.has(cid):
		cidToCardNode[cid].setCount(deckData[cid])
	setDeckText()
	hasSaved = false

func removeCardFromDeck(cid : int):
	if not deckData.has(cid):
		return
	
	deckData[cid] -= 1
	if deckData[cid] > 0:
		cidToButton[cid].text = getDeckButtonText(cid, deckData[cid])
	else:
		deckData.erase(cid)
		cidToButton[cid].queue_free()
		cidToButton.erase(cid)
	if cidToCardNode.has(cid):
		var cardCount : int = 0 if not deckData.has(cid) else deckData[cid]
		cidToCardNode[cid].setCount(cardCount)
	setDeckText()
	hasSaved = false

func getTotalCards() -> int:
	var total : int = 0
	for cid in deckData.keys():
		total += deckData[cid]
	return total

func setDeckText():
	deckLabel.text = "Deck (" + str(getTotalCards()) + "):"

static func getDeckButtonText(cid : int, count : int) -> String:
	return "x" + str(count) + " " + ListOfCards.cardList[cid].name

func onDeckCardPressed(cid : int):
	if lastMouseButtonIndex == MOUSE_BUTTON_LEFT:
		removeCardFromDeck(cid)
	elif lastMouseButtonIndex == MOUSE_BUTTON_RIGHT:
		var cardPage : int = findCardPage(cid)
		if cardPage != -1 and cardPage != page:
			setPage(cardPage)

func clearDeck():
	for cid in deckData.keys():
		deckData.erase(cid)
		cidToButton[cid].queue_free()
		cidToButton.erase(cid)

func setPlayerUUID(newPlayerUUID : int) -> void:
	var newDeckData : Dictionary = getSaveDeck(newPlayerUUID)
	setDeckData(newDeckData)
	var newCollectionData : Dictionary = getSaveCollection(newPlayerUUID)
	setCollectionData(newCollectionData)
	playerUUID = newPlayerUUID

func setDeckData(newDeckData : Dictionary) -> void:
	clearDeck()
	for cardID in newDeckData.keys():
		for i in range(newDeckData[cardID]):
			addCardToDeck(cardID)

func setCollectionData(newCollectionData : Dictionary) -> void:
	self.collectionData = newCollectionData
	updateFilters()

####################################################################################################
########## COLLECTION DISPLAY ######################################################################
####################################################################################################

func setPage(newPage : int):
	page = newPage
	cidToCardNode.clear()
	for i in range(PAGE_SIZE):
		var cardIndex : int = PAGE_SIZE * page + i
		if cardIndex < cards.size():
			if not cardNodes[i].visible:
				cardNodes[i].show()
				cardNodes[i].setIsSeen(false)
				
			cardNodes[i].flipToCard(cards[cardIndex])
			var cardCount : int = 0
			if deckData.has(cards[cardIndex].cid):
				cardCount = deckData[cards[cardIndex].cid]
			var cardMaxCount : int = 0
			if collectionData.has(cards[cardIndex].cid):
				cardMaxCount = collectionData[cards[cardIndex].cid]
			cardNodes[i].count = cardCount
			cardNodes[i].maxCount = cardMaxCount
			cidToCardNode[cards[cardIndex].cid] = cardNodes[i]
		else:
			cardNodes[i].hide()

func findCardPage(cid : int) -> int:
	for i in range(cards.size()):
		if cards[i].cid == cid:
			return i/PAGE_SIZE
	return -1

####################################################################################################
########## STATIC HELPER FUNCS #####################################################################
####################################################################################################

func onSaveButtonPressed() -> void:
	var saveData : Dictionary = FileIO.getSaveData()
	saveData[playerUUID]["deck_data"] = deckData
	FileIO.saveGame(saveData)
	noticeDialog.dialog_text = "\n       Deck Saved!"
	noticeDialog.popup()
	hasSaved = true

enum CONFIRM_TYPE {CLEAR, EXIT_NO_SAVE}
var clearOrMenu : CONFIRM_TYPE = CONFIRM_TYPE.CLEAR
func onClearButtonPressed() -> void:
	clearOrMenu = CONFIRM_TYPE.CLEAR
	confirmDialog.title = "Clear"
	confirmDialog.dialog_text = "\n Clear your current deck?"
	confirmDialog.show()

func onMainMenuButtonPressed() -> void:
	clearOrMenu = CONFIRM_TYPE.EXIT_NO_SAVE
	if not hasSaved:
		confirmDialog.title = "Exit"
		confirmDialog.dialog_text = "\n     Exit without Saving?"
		confirmDialog.show()
	else:
		onDialogConfirmed()

func onDialogConfirmed() -> void:
	if clearOrMenu == CONFIRM_TYPE.CLEAR:
		clearDeck()
	elif clearOrMenu == CONFIRM_TYPE.EXIT_NO_SAVE:
		var rankingsNode = Util.changeSceneToFileButDoesntSUCK_ASS(Preloader.rankingsPath)
		rankingsNode.movingFromGame = true




enum DECK_ERROR {OK, EMPTY, INVALID_KEY, KEY_OOB}
static func confirmDeckData(data : Dictionary) -> DECK_ERROR:
	if data.is_empty():
		return DECK_ERROR.EMPTY
	for k in data.keys():
		if not typeof(k) == TYPE_INT:
			return DECK_ERROR.INVALID_KEY
		elif k < 0 or k >= ListOfCards.cardList.size():
			return DECK_ERROR.KEY_OOB
	return DECK_ERROR.OK

static func getSaveDeck(playerUUID : int) -> Dictionary:
	var newDeckData : Dictionary = FileIO.getSaveData()[playerUUID]["deck_data"]
	return newDeckData

static func getSaveCollection(playerUUID : int) -> Dictionary:
	var newCollectionData : Dictionary = FileIO.getSaveData()[playerUUID]["collection"]
	return newCollectionData

const BST_MAX : String = "bst_max"
const DECK_SIZE : String = "deck_size"
const NULL_RAT : String = "null_rat"
const DIVERSITY : String = "div"
const BASE_PARAMS : Dictionary = {
	BST_MAX : -1, 
	DECK_SIZE : 40,
	NULL_RAT : 0.15,
	DIVERSITY : 0
}
static func genStartData(deckParams : Dictionary = {}) -> Dictionary:
	for k in BASE_PARAMS.keys():
		if not deckParams.has(k):
			deckParams[k] = BASE_PARAMS[k]
	
	var validCardsNonNull : Array = []
	var validCardsNull : Array = []
	for i in range(ListOfCards.cardList.size()):
		var card : Card = ListOfCards.getCard(i)
		if deckParams[BST_MAX] != -1 and card.attack + card.health > deckParams[BST_MAX]:
			continue
		if card.rarity != Card.RARITY.BASIC:
			continue
		if card.creatureTypes.has(Card.CREATURE_TYPE.NULL):
			validCardsNull.append(card)
		else:
			validCardsNonNull.append(card)
	var rtn : Dictionary = {}
	for i in range(deckParams[DECK_SIZE]):
		var card : Card = null
		if randf() < deckParams[NULL_RAT]:
			card = validCardsNull[randi() % validCardsNull.size()].duplicate()
		else:
			card = validCardsNonNull[randi() % validCardsNonNull.size()].duplicate()
		if not rtn.has(card.cid):
			rtn[card.cid] = 0
		rtn[card.cid] += 1
	return rtn
