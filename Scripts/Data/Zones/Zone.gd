extends RefCounted

class_name Zone

const ZONE_HAND : int = 1
const ZONE_DECK : int = 2
const ZONE_IN_PLAY : int = 3
const ZONE_FUSION : int = 4

var cards : Array = []
var player : Player

signal before_card_set(card : Card, index : int)
signal after_card_set(card : Card, index : int)
signal before_card_added(card : Card)
signal after_card_added(card : Card)
signal before_card_removed(card : Card)
signal after_card_removed(card : Card)
signal before_shuffle()
signal after_shuffle()
signal after_card_moved(card : Card, index : int)
signal changed()

############################################################################

func setPlayer(newPlayer : Player):
	self.player = newPlayer

############################################################################

func removeCard(index : int):
	if index < 0 or index >= cards.size():
		return
	var card : Card = cards[index]
	before_card_removed.emit(card)
	cards.remove_at(index)
	after_card_removed.emit(card)
	changed.emit()

func eraseCard(card : Card):
	removeCard(cards.find(card))

func eraseCards(removedCards : Array):
	for card in removedCards:
		before_card_removed.emit(card)
	for card in removedCards:
		cards.erase(card)
	for card in removedCards:
		after_card_removed.emit(card)
	changed.emit()

func clear():
	eraseCards(cards.duplicate())

############################################################################

func insertCard(newCard : Card, newIndex : int):
	before_card_added.emit(newCard)
	cards.insert(newIndex, newCard)
	after_card_added.emit(newCard)
	after_card_moved.emit(newCard, newIndex)
	changed.emit()

func addCard(newCard : Card):
	insertCard(newCard, cards.size())

func addCards(newCards : Array):
	for card in newCards:
		before_card_added.emit(card)
	for card in newCards:
		cards.append(card)
	for card in newCards:
		after_card_added.emit(card)
	changed.emit()
	
func setCard(newCard : Card, newIndex : int):
	if newCard == null and cards[newIndex] == null:
		return
	
	removeCard(newIndex)
	
	if newCard != null:
		before_card_added.emit(newCard)
	before_card_set.emit(newCard, newIndex)
	cards.insert(newIndex, newCard)
	if newCard != null:
		newCard.destroyed.connect(self.onCardDestroyed.bind(newCard))
		after_card_added.emit(newCard)
	after_card_set.emit(newCard, newIndex)
	changed.emit()

func onCardDestroyed(card : Card):
	pass
	#var index : int = cards.find(card)
	#if index != -1:
	#	setCard(null, index)

############################################################################

func setCards(newCards : Array):
	clear()
	addCards(newCards)

func setData(data : Dictionary):
	var newCards : Array = []
	for cid in data.keys():
		for i in range(data[cid]):
			newCards.append(ListOfCards.getCard(cid))
	setCards(newCards)

func setDataSerialized(serializedData : Array):
	var nCards : int = serializedData.size()
	for i in range(nCards):
		if serializedData[i] == null:
			setCard(null, i)
		else:
			var newCard : Card = ListOfCards.getCard(serializedData[i]["cid"])
			newCard.deserialize(serializedData[i])
			setCard(newCard, i)
	for j in range(cards.size()-1, nCards, -1):
		removeCard(j)

func moveCard(card : Card, newIndex : int):
	moveIndex(cards.find(card), newIndex)

func moveIndex(oldIndex : int, newIndex : int):
	var tmp = cards[oldIndex]
	cards.remove_at(oldIndex)
	cards.insert(newIndex, tmp)
	after_card_moved.emit(tmp, newIndex)

############################################################################

func shuffle():
	before_shuffle.emit()
	cards.shuffle()
	after_shuffle.emit()
	changed.emit()
