extends ZoneNode

class_name InPlayNode

var buttons : Array = []
var cardNodeToButton : Dictionary = {}

func initModes() -> void:
	setSeenMode(SEEN_MODE.SEEN)
	setOffsetMode(OFF_MODE.ROW_WIDE)

func setInPlayZone(newInPlayZone : InPlayZone):
	if self.zone != null:
		self.zone.disconnect("after_card_set", self.onZoneCardSet)
	setZone(newInPlayZone)
	self.zone.connect("after_card_set", self.onZoneCardSet)

func onZoneCardAdded(card : Card) -> CardNode:
	var cardNode = super.onZoneCardAdded(card)
	if card == null:
		buttons.append(cardNode)
		cardNode.setHiddenButton()
	return cardNode

func onZoneCardSet(card : Card, index : int):
	var button : CardNode = buttons[index]
	button.visible = (card == null)
	if card != null:
		var cardNode : CardNode = boardNode.getCardNode(card)
		moveCardNode(cardNode, index)
		cardNodeToButton[cardNode] = button
		cardNodes.erase(button)
	else:
		for cn in cardNodeToButton.keys():
			if cardNodeToButton[cn] == button:
				cardNodeToButton.erase(cn)
				break
		cardNodes.insert(index, button)

func onZoneCardRemoved(card : Card):
	var cardNode : CardNode = boardNode.getCardNode(card, false)
	if cardNode != null:
		eraseCardNode(cardNode)
