extends ZoneNode

class_name DeckNode

var shuffling : bool = false
var shuffleTimer : float = 0.0
const shuffleMaxTime : float = 0.45

func initModes() -> void:
	setSeenMode(SEEN_MODE.CONCEALED)
	setOffsetMode(OFF_MODE.PILE_NARROW)

func setZone(newZone : Zone):
	if self.zone != null:
		self.zone.disconnect("after_mill", self.onDeckMill)
	super.setZone(newZone)
	self.zone.connect("after_mill", self.onDeckMill)

func setDeck(newDeck : Deck):
	setZone(newDeck)

func onDeckMill(amount : int):
	var removed : Array = []
	for cardNode in cardNodes:
		if not cardNode.card in zone.cards:
			removed.append(cardNode)
	pass
