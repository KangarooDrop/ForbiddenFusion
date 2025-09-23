extends RefCounted

class_name Zone

const ZONE_HAND : int = 1
const ZONE_DECK : int = 2
const ZONE_IN_PLAY : int = 3
const ZONE_FUSION : int = 4

var cards : Array = []
var player : Player

signal before_card_added(card : Card)
signal after_card_added(card : Card)
signal before_card_removed(card : Card)
signal after_card_removed(card : Card)
signal before_shuffle()
signal after_shuffle()
signal after_card_moved(card : Card, index : int)
signal changed()

############################################################################

func setPlayer(player : Player):
	self.player = player

############################################################################

func removeCard(index : int):
	if index < 0 or index >= cards.size():
		return
	var card : Card = cards[index]
	emit_signal("before_card_removed", card)
	cards.remove_at(index)
	emit_signal("after_card_removed", card)
	emit_signal("changed")

func eraseCard(card : Card):
	removeCard(cards.find(card))

func eraseCards(removedCards : Array):
	for card in removedCards:
		emit_signal("before_card_removed", card)
	for card in removedCards:
		cards.erase(card)
	for card in removedCards:
		emit_signal("after_card_removed", card)
	emit_signal("changed")

func clear():
	eraseCards(cards.duplicate())

############################################################################

func insertCard(newCard : Card, newIndex : int):
	emit_signal("before_card_added", newCard)
	cards.insert(newIndex, newCard)
	emit_signal("after_card_added", newCard)
	emit_signal("after_card_moved", newCard, newIndex)
	emit_signal("changed")

func addCard(newCard : Card):
	insertCard(newCard, cards.size())

func addCards(newCards : Array):
	for card in newCards:
		emit_signal("before_card_added", card)
	for card in newCards:
		cards.append(card)
	for card in newCards:
		emit_signal("after_card_added", card)
	emit_signal("changed")
	
func setCard(newCard : Card, newIndex : int):
	if newCard == null and cards[newIndex] == null:
		return
	
	removeCard(newIndex)
	
	if newCard != null:
		emit_signal("before_card_added", newCard)
	emit_signal("before_card_set", newCard, newIndex)
	cards.insert(newIndex, newCard)
	if newCard != null:
		newCard.connect("destroyed", self.onCardDestroyed.bind(newCard))
		emit_signal("after_card_added", newCard)
	emit_signal("after_card_set", newCard, newIndex)
	emit_signal("changed")

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
	emit_signal("after_card_moved", tmp, newIndex)

############################################################################

func shuffle():
	emit_signal("before_shuffle")
	cards.shuffle()
	emit_signal("after_shuffle")
	emit_signal("changed")
