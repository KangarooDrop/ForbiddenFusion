extends Node

class_name RewardNode

signal card_pressed(cid : int)
signal skip_pressed()

var allCardNodes : Array = []
@onready var center : Control = $Center
@onready var cardNodeHolder : Node2D = $CardNodeHolder
@onready var skipButton : NinePatchButton = $Center/Node2D/ColorRect/SkipButton

func addCards(cardIndices : Array) -> void:
	for cid in cardIndices:
		addCard(cid)

func addCard(cid : int) -> void:
	var card : Card = ListOfCards.getCard(cid)
	var cardNode : CardNode = Preloader.cardNodePacked.instantiate()
	cardNodeHolder.add_child(cardNode)
	cardNode.setCard(card)
	cardNode.setIsSeen(true)
	cardNode.global_position = Vector2.ZERO
	cardNode.global_position = center.global_position
	cardNode.mouse_enter.connect(self.onCardMouseEnter.bind(cardNode))
	cardNode.mouse_exit.connect(self.onCardMouseExit.bind(cardNode))
	cardNode.button_down.connect(self.onCardButtonDown.bind(cardNode))
	cardNode.button_up.connect(self.onCardButtonUp.bind(cardNode))
	cardNode.pressed.connect(self.onCardPressed.bind(cardNode))
	
	allCardNodes.append(cardNode)
	
func _process(_delta : float) -> void:
	var numCards : int = allCardNodes.size()
	for i in range(numCards):
		if is_instance_valid(allCardNodes[i]):
			var cn : CardNode = allCardNodes[i]
			cn.desiredPosition = center.global_position + Vector2((i - (numCards - 1)/2.0) * (ListOfCards.CARD_WIDTH + 8), 0.0)

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
		card_pressed.emit(cardNode.card.cid)
		cardNode.queue_free()
		
		var isValid : bool = false
		for cn in allCardNodes:
			if is_instance_valid(cn) and not cn == cardNode:
				isValid = true
		if not isValid:
			var oldButtonSizeX : float = skipButton.size.x
			skipButton.text = "Next Fight"
			skipButton.position.x += (oldButtonSizeX - skipButton.size.x)/2.0
		
func onSkipPressed() -> void:
	skip_pressed.emit()
