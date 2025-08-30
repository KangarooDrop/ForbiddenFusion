extends CardDisplay

class_name ZoneNode

var zone : Zone
@onready var boardNode : BoardNode = get_parent()

func _ready() -> void:
	initModes()

func initModes() -> void:
	setSeenMode(SEEN_MODE.INHERITED)
	setOffsetMode(OFF_MODE.ROW_WIDE)

func addCardNode(cardNode : CardNode):
	super.addCardNode(cardNode)
	boardNode.cardNodeToZoneNode[cardNode] = self

func removeCardNode(index : int):
	var oldCardNode : CardNode = cardNodes[index]
	super.removeCardNode(index)
	if boardNode.cardNodeToZoneNode[oldCardNode] == self:
		boardNode.cardNodeToZoneNode.erase(oldCardNode)

func onZoneCardAdded(card : Card) -> CardNode:
	var cardNode = boardNode.getCardNode(card)
	addCardNode(cardNode)
	return cardNode

func onZoneCardRemoved(card : Card):
	var cardNode : CardNode = boardNode.getCardNode(card, false)
	if cardNode != null:
		eraseCardNode(cardNode)

func onZoneCardMoved(card : Card, newIndex : int):
	for cn in cardNodes:
		if cn.card == card:
			moveCardNode(cn, newIndex)
			break

func setZone(newZone : Zone):
	if self.zone == newZone:
		return
	
	if self.zone != null:
		for card in self.zone.cards:
			onZoneCardRemoved(card)
		self.zone.disconnect("after_card_added", self.onZoneCardAdded)
		self.zone.disconnect("after_card_removed", self.onZoneCardRemoved)
		self.zone.disconnect("after_card_moved", self.onZoneCardMoved)
	
	self.zone = newZone
	
	for card in newZone.cards:
		onZoneCardAdded(card)
	
	newZone.connect("after_card_added", self.onZoneCardAdded)
	newZone.connect("before_card_removed", self.onZoneCardRemoved)
	newZone.connect("after_card_moved", self.onZoneCardMoved)

func _process(delta: float) -> void:
	super._process(delta)
	
	for cn in cardNodes:
		var realZone = boardNode.cardNodeToZoneNode[cn]
		assert(realZone == self, "ERROR: Mismatched zones detected!")
