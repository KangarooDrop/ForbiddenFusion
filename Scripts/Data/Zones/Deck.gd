extends Zone

class_name Deck

signal before_draw(pointer : Array)
signal after_draw(amount : int)
signal before_mill(pointer : Array)
signal after_mill(amount : int)

############################################################################

func draw(amount : int = 1):
	var amountPointer : Array = [amount]
	emit_signal("before_draw", amountPointer)
	amount = amountPointer[0]
	for i in range(amount):
		if cards.size() > 0:
			var card : Card = cards[0]
			removeCard(0)
			player.hand.addCard(card)
	emit_signal("after_draw", amount)
	emit_signal("changed")

func mill(amount : int = 1):
	var amountPointer : Array = [amount]
	emit_signal("before_mill", amountPointer)
	amount = amountPointer[0]
	for i in range(amount):
		if cards.size() > 0:
			cards.remove_at(0)
	emit_signal("after_mill", amount)
	emit_signal("changed")
