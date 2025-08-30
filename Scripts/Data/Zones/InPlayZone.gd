extends Zone

class_name InPlayZone

var numSlots : int = 0

signal before_card_set(card : Card, index : int)
signal after_card_set(card : Card, index : int)

func setNumSlots(newNumSlots : int):
	var d : int = newNumSlots - numSlots
	if d > 0:
		for i in range(d):
			cards.append(null)
	elif d < 0:
		for i in range(-d):
			var indexRemoved : int = cards.size()-1-i
			if cards[indexRemoved] != null:
				removeCard(indexRemoved)
			else:
				cards.remove_at(indexRemoved)
	self.numSlots = newNumSlots

func isEmpty(index : int) -> bool:
	if index < 0 or index >= cards.size():
		return false
	return cards[index] == null

func removeCard(index : int):
	if not isEmpty(index):
		super.removeCard(index)
	else:
		cards.remove_at(index)

"""
func setCard(newCard : Card, newIndex : int):
	removeCard(newIndex)
	
	emit_signal("before_card_set", newCard, newIndex)
	insertCard(newCard, newIndex)
	if newCard != null:
		newCard.connect("destroyed", self.onCardDestroyed.bind(newCard))
	emit_signal("after_card_set", newCard, newIndex)
"""
