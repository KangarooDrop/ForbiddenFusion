extends Node2D

class_name CardVisual

@onready var label = $Label
@onready var eyeSprite = $EyeSprite
@onready var cardPortrait  = $CardPortrait
@onready var cardBackground = $CardBackground
@onready var cardType = $CardType
@onready var cardType2 = $CardType2
@onready var cardRarity = $CardRarity
@onready var cardback = $Cardback

func showCard(card : Card):
	cardPortrait.visible = true
	cardback.visible = false
	
	if card != null:
		label.visible = true
		label.text = str(card.attack) + "/" + str(card.health)
		if card.creatureTypes.size() > 0:
			cardType.visible = true
			cardType.region_rect.position.x = card.creatureTypes[0] * 8
		else:
			cardType.visible = false
		
		if card.creatureTypes.size() > 1:
			cardType2.visible = true
			cardType2.region_rect.position.x = card.creatureTypes[1] * 8
		else:
			cardType2.visible = false
		
		cardPortrait.texture = card.texture
		cardRarity.visible = true
		cardRarity.region_rect = Rect2(Vector2(14 * (card.rarity - 1), 0), Vector2(14, 14))
	else:
		cardPortrait.texture = Preloader.noneCardTex
		label.visible = false
		cardRarity.visible = false

func showUnknown():
	cardPortrait.visible = false
	cardType.visible = false
	cardType2.visible = false
	label.visible = false
	cardRarity.visible = false
	
	cardback.visible = true
	cardback.texture = Preloader.cardbackDefault

func showToOpponent():
	eyeSprite.show()
