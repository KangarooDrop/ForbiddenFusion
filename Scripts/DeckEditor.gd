extends Node

class_name DeckEditor

@onready var cardNodeHolder : Node2D = $CardNodeHolder
@onready var deckCardButtonBase : Button = $DeckHolder/VBoxContainer/DeckCardButton
@onready var deckVBox : VBoxContainer = $DeckHolder/VBoxContainer
@onready var deckLabel : Label = $DeckHolder/VBoxContainer/Label

@onready var noticeDialog : AcceptDialog = $Control/NoticeDialog
@onready var confirmDialog : ConfirmationDialog = $Control/ConfirmDialog
@onready var fileDialog : FileDialog = $Control/FileDialog

const WIDTH : int = 3
const HEIGHT : int = 2
const PAGE_SIZE : int = WIDTH*HEIGHT
const BUFFER : int = 6
const CARD_OFFSET : Vector2 = ListOfCards.CARD_SIZE + Vector2i.ONE * BUFFER

var page : int = 0
var cards : Array = []
var cardNodes : Array = []

var deckData : Dictionary = {}
var uuidToButton : Dictionary = {}

func _ready() -> void:
	for y in range(HEIGHT):
		for x in range(WIDTH):
			var cardNode : CardNode = Preloader.cardNodePacked.instantiate()
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
	cards = ListOfCards.cardList.duplicate()
	for i in range(cards.size()-1, -1, -1):
		if cards[i].rarity != Card.RARITY.BASIC:
			cards.remove_at(i)
	setPage(0)
	setDeckText()

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
		addCardToDeck(cardNode.card.UUID)

func addCardToDeck(UUID : int):
	if not deckData.has(UUID):
		var deckCardButton = deckCardButtonBase.duplicate()
		deckCardButton.show()
		deckCardButton.connect("pressed", self.onDeckCardPressed.bind(UUID))
		deckVBox.add_child(deckCardButton)
		deckData[UUID] = 0
		uuidToButton[UUID] = deckCardButton
	deckData[UUID] += 1
	uuidToButton[UUID].text = getDeckButtonText(UUID, deckData[UUID])
	setDeckText()

func removeCardFromDeck(UUID : int):
	deckData[UUID] -= 1
	if deckData[UUID] > 0:
		uuidToButton[UUID].text = getDeckButtonText(UUID, deckData[UUID])
	else:
		deckData.erase(UUID)
		uuidToButton[UUID].queue_free()
		uuidToButton.erase(UUID)
	setDeckText()

func getTotalCards() -> int:
	var total : int = 0
	for UUID in deckData.keys():
		total += deckData[UUID]
	return total

func setDeckText():
	deckLabel.text = "Deck (" + str(getTotalCards()) + "):"

static func getDeckButtonText(UUID : int, count : int) -> String:
	return "x" + str(count) + " " + ListOfCards.cardList[UUID].name

func onDeckCardPressed(UUID : int):
	removeCardFromDeck(UUID)

func clearDeck():
	for UUID in deckData.keys():
		deckData.erase(UUID)
		uuidToButton[UUID].queue_free()
		uuidToButton.erase(UUID)

func setPage(newPage : int):
	page = newPage
	for i in range(PAGE_SIZE):
		var cardIndex : int = PAGE_SIZE * page + i
		if cardIndex < cards.size():
			if not cardNodes[i].visible:
				cardNodes[i].show()
				cardNodes[i].setIsSeen(false)
				
			cardNodes[i].flipToCard(cards[cardIndex])
		else:
			cardNodes[i].hide()

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
			var deckData : Dictionary = {}
			for i in range(deckSize):
				var cardIndex : int = randi() % cards.size()
				var UUID : int = cards[cardIndex].UUID
				addCardToDeck(UUID)

var savingOrLoading : int = 0
func onSaveButtonPressed() -> void:
	savingOrLoading = 1
	fileDialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	fileDialog.show()

func onLoadButtonPressed() -> void:
	savingOrLoading = 2
	fileDialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fileDialog.show()

func onFileSelected(path: String) -> void:
	if savingOrLoading == 1:
		FileIO.writeToJSON(path, deckData)
	elif savingOrLoading == 2:
		var loadedData : Dictionary = loadDeckData(path)
		var error : DECK_ERROR = confirmDeckData(loadedData)
		if error != DECK_ERROR.OK:
			noticeDialog.dialog_text = "Error: Deck file couln't be loaded."
			return
		clearDeck()
		for k in loadedData.keys():
			var UUID : int = int(k)
			var count : int = int(loadedData[k])
			for i in range(count):
				addCardToDeck(UUID)

var clearOrMenu : int = 0
func onClearButtonPressed() -> void:
	clearOrMenu = 1
	confirmDialog.title = "Clear"
	confirmDialog.dialog_text = "\n Clear your current deck?"
	confirmDialog.show()

func onMainMenuButtonPressed() -> void:
	clearOrMenu = 2
	confirmDialog.title = "Exit"
	confirmDialog.dialog_text = "\n     Go to Main Menu?"
	confirmDialog.show()

func onDialogConfirmed() -> void:
	if clearOrMenu == 1:
		clearDeck()
	elif clearOrMenu == 2:
		get_tree().change_scene_to_file(Preloader.mainMenuPath)

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

static func loadDeckData(deckPath : String) -> Dictionary:
	var rtn : Dictionary = {}
	var data : Dictionary = FileIO.readFromJSON(deckPath)
	if data.is_empty():
		return {}
	
	for k in data.keys():
		if typeof(k) != TYPE_STRING or not k.is_valid_int():
			continue
		if typeof(data[k]) != TYPE_FLOAT:
			continue
		rtn[int(k)] = int(data[k])
	return rtn
