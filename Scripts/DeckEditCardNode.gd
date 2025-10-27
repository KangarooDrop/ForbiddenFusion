extends CardNode

var count : int = 0
var maxCount : int = 0

@onready var countLabel : Label = $Label

func setCount(newCount) -> void:
	self.count = newCount
	updateCountData()

func setMaxCount(newMaxCount : int) -> void:
	self.maxCount = newMaxCount
	updateCountData()

func setCard(newCard : Card) -> void:
	super.setCard(newCard)
	updateCountData()

func updateCountData() -> void:
	countLabel.text = str(count) + "/" + str(maxCount)
	setHasAttackedThisTurn(count >= maxCount)
