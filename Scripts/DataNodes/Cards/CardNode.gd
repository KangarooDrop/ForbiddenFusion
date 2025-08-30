extends Node2D

class_name CardNode

var card : Card
var isSeen : bool = false
var hovering : bool = false
var pressing : bool = false
var disabled : bool = false

var showHovering : bool = false
var showPressed : bool = false

var moveDelay : float = 0.0

signal mouse_enter()
signal mouse_exit()
signal button_down(buttonIndex : int)
signal button_up(buttonIndex : int)
signal pressed(buttonIndex : int)
signal flip_ended()
signal card_changed(oldCard : Card, newCard : Card)
signal destroyed()

@onready var cardVisual : CardVisual = $CardVisual
@onready var slotSprite : Sprite2D = $SlotSprite

func setCard(newCard : Card):
	var oldCard = self.card
	if self.card != null:
		disconnectCard()
	self.card = newCard
	updateVisuals()
	if self.card != null:
		connectCard()
	
	emit_signal("card_changed", oldCard, newCard)

func updateVisuals():
	if isSeen:
		cardVisual.showCard(card)
	else:
		cardVisual.showUnknown()

func connectCard():
	self.card.connect("destroyed", self.onDestroy.bind(true))
	self.card.connect("changed", self.onCardChanged)

func disconnectCard():
	self.card.disconnect("destroyed", self.onDestroy)
	self.card.disconnect("changed", self.onCardChanged)

func onCardChanged():
	updateVisuals()
	emit_signal("card_changed", null, self.card)

func setHiddenButton():
	cardVisual.hide()
	slotSprite.show()

func setIsSeen(newSeen : bool):
	if newSeen:
		cardVisual.showCard(card)
	else:
		cardVisual.showUnknown()
	self.isSeen = newSeen

func showToOpponent():
	setIsSeen(true)
	cardVisual.showToOpponent()

func onMouseEnter() -> void:
	hovering = true
	emit_signal("mouse_enter")

func onMouseExit() -> void:
	hovering = false
	emit_signal("mouse_exit")

func _input(event: InputEvent) -> void:
	if not hovering and not pressing:
		return
	if not event is InputEventMouseButton:
		return
	
	if event.is_pressed():
		pressing = true
		emit_signal("button_down", event.button_index)
	elif pressing:
		pressing = false
		emit_signal("button_up", event.button_index)
		if hovering:
			emit_signal("pressed", event.button_index)

var flipping : bool = false
var hasFlipped : bool = false
var flippingToSame = false
var flippingToCard = null
var flipTimer = 0
var flipMaxTime = 0.5

var desiredPosition = null

func flip():
	flipping = true

func flipSame():
	flippingToSame = true
	flip()

func flipToCard(card : Card):
	if isSeen:
		flipSame()
	else:
		flip()
	flippingToCard = card

func _process(delta: float) -> void:
	var desiredScale : Vector2 = Vector2.ONE
	if showHovering:
		desiredScale *= 1.1
	if showPressed:
		desiredScale *= 1.1
	cardVisual.scale = lerp(cardVisual.scale, desiredScale, 16.0 * delta)
	
	if desiredPosition != null:
		if moveDelay > 0.0:
			moveDelay -= delta
		else:
			global_position = lerp(global_position, desiredPosition, 8.0 * delta)
	
	
	if flipping:
		flipTimer += delta
		var t : float = flipTimer/flipMaxTime
		if t > 0.5 and not hasFlipped:
			hasFlipped = true
			if not flippingToSame:
				setIsSeen(not isSeen)
			if flippingToCard != null:
				setCard(flippingToCard)
		var s : float = (cos(t*2*PI)+1.0)/2.0
		scale.x = s
		if flipTimer >= flipMaxTime:
			flipping = false
			flipTimer = 0.0
			hasFlipped = false
			flippingToSame = false
			flippingToCard = null
			scale.x = 1.0
			emit_signal("flip_ended")

func onDestroy(fromSelfCard : bool = false):
	emit_signal("destroyed")
	if not fromSelfCard:
		self.card.onDestroy()
	else:
		queue_free()
