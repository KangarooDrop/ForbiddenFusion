extends Node2D

class_name BoardNode

signal card_node_pressed(cardNode, buttonIndex)
signal turn_passed()
signal fusion_finished()
signal move_camera(offset : int)
signal game_end()

var board : Board

var winner : Player = null

@onready var cardNodeHolder : Node2D = $CardNodeHolder
@onready var playerHandDisplay : HandNode = $PlayerHandZone
@onready var opponentHandDisplay : HandNode = $OpponentHandZone
@onready var playerFusionDisplay : CardDisplay = $PlayerFusionZone
@onready var opponentFusionDisplay : CardDisplay = $OpponentFusionZone
@onready var playerDeckDisplay : DeckNode = $PlayerDeckZone
@onready var opponentDeckDisplay : DeckNode = $OpponentDeckZone
@onready var playerInPlayDisplay : CardDisplay = $PlayerInPlayZone
@onready var opponentInPlayDisplay : CardDisplay = $OpponentInPlayZone
var zoneToNode : Dictionary = {}
@onready var turnIndicator : Polygon2D = $TurnIndicator
@onready var playerHealthNode : Sprite2D = $PlayerHealthNode
@onready var playerHealthLabel : Label = playerHealthNode.get_node("Label")
@onready var opponentHealthNode : Sprite2D = $OpponentHealthNode
@onready var opponentHealthLabel : Label = opponentHealthNode.get_node("Label")
@onready var winLoseSprite : Sprite2D = $WinLoseSprite

var turnChanging : bool = false
var turnJumpTimer : float = 0.0
const turnJumpMaxTime : float = 0.35

var cardNodes : Array = []
var cardNodeToZoneNode : Dictionary = {}
func getCardNodeToZoneNode(cardNode):
	if not cardNodeToZoneNode.has(cardNode):
		return null
	return cardNodeToZoneNode[cardNode]

func initDecksAndStart() -> void:
	board.players[0].deck.shuffle()
	board.players[1].deck.shuffle()
	
	#Starting Game
	board.startGame()

func _ready() -> void:
	#Creating board
	var numPlayers : int = 2
	board = Board.new(numPlayers)
	board.connect("turn_started", self.onTurnStarted)
	
	#Loading Decks
	#board.players[0].deck.loadDeckFile("res://Decks/deck_test.json")
	playerDeckDisplay.setDeck(board.players[0].deck)
	zoneToNode[board.players[0].deck] = playerDeckDisplay
	playerHandDisplay.setHand(board.players[0].hand)
	zoneToNode[board.players[0].hand] = playerHandDisplay
	playerHandDisplay.setSeenMode(CardDisplay.SEEN_MODE.SEEN)
	playerFusionDisplay.setZone(board.getPlayerToFusionZone(board.players[0]))
	zoneToNode[board.getPlayerToFusionZone(board.players[0])] = playerFusionDisplay
	playerInPlayDisplay.setInPlayZone(board.getPlayerToInPlayZone(board.players[0]))
	zoneToNode[board.getPlayerToInPlayZone(board.players[0])] = playerInPlayDisplay
	board.players[0].connect("after_game_loss", self.onPlayerGameLoss.bind(board.players[0]))
	board.players[0].connect("after_health_change", self.onPlayerHealthChange.bind(board.players[0]))
	
	opponentDeckDisplay.setDeck(board.players[1].deck)
	zoneToNode[board.players[1].deck] = opponentDeckDisplay
	opponentHandDisplay.setHand(board.players[1].hand)
	zoneToNode[board.players[1].hand] = opponentHandDisplay
	opponentFusionDisplay.setZone(board.getPlayerToFusionZone(board.players[1]))
	zoneToNode[board.getPlayerToFusionZone(board.players[1])] = opponentFusionDisplay
	opponentInPlayDisplay.setInPlayZone(board.getPlayerToInPlayZone(board.players[1]))
	zoneToNode[board.getPlayerToInPlayZone(board.players[1])] = opponentInPlayDisplay
	board.players[1].connect("after_game_loss", self.onPlayerGameLoss.bind(board.players[1]))
	board.players[1].connect("after_health_change", self.onPlayerHealthChange.bind(board.players[1]))

var gameIsOver : bool = false
func onPlayerGameLoss(player : Player):
	if player == board.players[0]:
		winLoseSprite.region_rect.position.y = 32.0
	elif player == board.players[1]:
		winLoseSprite.region_rect.position.y = 0.0
	winLoseSprite.show()
	gameIsOver = true
	winner = board.getOpponent(player)
	
	game_end.emit()

func onPlayerHealthChange(amountPointer : Array, player : Player):
	var label : Label
	if player == board.players[0]:
		label = playerHealthLabel
	elif player == board.players[1]:
		label = opponentHealthLabel
	else:
		return
	label.text = str(player.health)
	label.size.x = 0.0
	label.position.x = -label.size.x/2.0

var cardToCardNode : Dictionary = {}
func onCardNodeCardChange(oldCard : Card, newCard : Card, cardNode : CardNode):
	if oldCard != null and cardToCardNode.has(oldCard):
		cardToCardNode.erase(oldCard)
	cardToCardNode[cardNode.card] = cardNode

func getCardNode(card : Card, createIfNotExists : bool = true) -> CardNode:
	if card == null or not cardToCardNode.has(card):
		if not createIfNotExists:
			return null
		else:
			return createCardNode(card)
	else:
		return cardToCardNode[card]

func createCardNode(card = null, isSeen : bool = false):
	var cardNode : CardNode = Preloader.cardNodePacked.instantiate()
	cardNodeHolder.add_child(cardNode)
	cardNode.setCard(card)
	cardNode.setIsSeen(isSeen)
	cardNode.global_position = Vector2.ZERO
	#cardNode.global_position = get_global_mouse_position()
	cardNode.mouse_enter.connect(self.onCardMouseEnter.bind(cardNode))
	cardNode.mouse_exit.connect(self.onCardMouseExit.bind(cardNode))
	cardNode.button_down.connect(self.onCardButtonDown.bind(cardNode))
	cardNode.button_up.connect(self.onCardButtonUp.bind(cardNode))
	cardNode.pressed.connect(self.onCardPressed.bind(cardNode))
	cardNode.card_changed.connect(self.onCardNodeCardChange.bind(cardNode))
	cardNodes.append(cardNode)
	cardToCardNode[card] = cardNode
	return cardNode

func checkStates():
	for player in board.players:
		var inpZone : InPlayZone = board.getPlayerToInPlayZone(player)
		for i in range(inpZone.cards.size()):
			if inpZone.cards[i] != null and inpZone.cards[i].health <= 0:
				var cardNode : CardNode = getCardNode(inpZone.cards[i], false)
				inpZone.setCard(null, i)
				cardNode.queue_free()
				#inpZone.cards[i].emit_signal("destroyed")

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
func onCardPressed(buttonIndex : int, cardNode : CardNode, sendToServer : bool = true):
	var fromServer : bool = not sendToServer
	if sendToServer:
		card_node_pressed.emit(cardNode, buttonIndex)
	
	if gameIsOver or cardNodesFusing.size() > 0:
		return
	
	if buttonIndex == MOUSE_BUTTON_LEFT:
		#Card in Hand
		var zoneNode : ZoneNode = getCardNodeToZoneNode(cardNode)
		if board.activePlayer.hand.cards.has(cardNode.card):
			if board.activePlayer != board.players[0] and not fromServer:
				return
			if hasFusedThisTurn:
				return
			board.activePlayer.hand.eraseCard(cardNode.card)
			board.playerToFusionZone[board.activePlayer].addCard(cardNode.card)
		#Card in Fusion Zone
		elif board.playerToFusionZone[board.activePlayer].cards.has(cardNode.card):
			board.playerToFusionZone[board.activePlayer].eraseCard(cardNode.card)
			board.activePlayer.hand.addCard(cardNode.card)
		#Card in Play
		elif cardNodeToZoneNode[cardNode].zone is InPlayZone:
			var inpZoneNode : InPlayNode = cardNodeToZoneNode[cardNode]
			var fusionZone : FusionZone = board.getPlayerToFusionZone(board.activePlayer)
			#When Fusing
			if fusionZone.cards.size() > 0:
				#Fusing to occupied slot
				if inpZoneNode.cardNodeToButton.has(cardNode):
					fuseEndSlot = inpZoneNode.cardNodeToButton[cardNode]
					fuseWasInPlay = true
					var index : int = inpZoneNode.cardNodes.find(cardNode)
					inpZoneNode.zone.setCard(null, index)
					fusionZone.insertCard(cardNode.card, 0)
					fuseInitialWait = 1.0
				else:
				#Fusing to empty slot
					fuseEndSlot = cardNode
					fuseWasInPlay = false
					#if board.activePlayer == board.players[0]:
					#	fuseInitialWait = 0.75
					#else:
					fuseInitialWait = 0.75
				
				zoneToNode[fusionZone].flipAllToFront()
				for cn in zoneToNode[fusionZone].cardNodes.duplicate():
					cardNodesFusing.append(cn)
				hasFusedThisTurn = true
				move_camera.emit(0)
			#Not fusing/Selecting
			else:
				#Active player clicking own card
				if inpZoneNode.zone.player == board.activePlayer:
					if cardNode != null and cardNode.hasAttackedThisTurn:
						return
					if not hasFusedThisTurn:
						return
					
					selectTimer = 0.0
					if selectedCardNode != null:
						selectedCardNode.rotation = 0.0
					if selectedCardNode == cardNode:
						selectedCardNode = null
					elif cardNode.card != null:
						selectedCardNode = cardNode
				elif selectedCardNode != null:
					
					var attackingCard : Card = selectedCardNode.card
					var defendingCard : Card = cardNode.card
					if defendingCard == null:
						for card in inpZoneNode.zone.cards:
							if card != null:
								return
						#Attacking directly
						var attackedPlayer : Player = cardNodeToZoneNode[cardNode].zone.player
						attackedPlayer.addHealth(-attackingCard.attack)
					else:
						"""
						#Attacking another creature
						#1: Damage is dealt to health and stays like Hearthstone.
						
						defendingCard.health -= attackingCard.attack
						defendingCard.emit_signal("changed")
						attackingCard.health -= defendingCard.attack
						attackingCard.emit_signal("changed")
						"""
						#2: Damage is compared against opposing damage/health like Yugioh.
						var attackerDestroyed : bool = attackingCard.health <= defendingCard.attack
						var defenderDestroyed : bool = defendingCard.health <= attackingCard.attack
						if attackerDestroyed:
							attackingCard.health = 0
							attackingCard.emit_signal("changed")
						if defenderDestroyed:
							defendingCard.health = 0
							defendingCard.emit_signal("changed")
						
						#3: Damage is dealt but resets at the end of a turn like Magic.
						
						#Different kinds of attacking/damage modes:
						#	1: Damage is dealt to health and stays like Hearthstone.
						#	2: Damage is compared against opposing damage/health like Yugioh.
						#	3: Damage is dealt but resets at the end of a turn like Magic.
					selectedCardNode.setHasAttackedThisTurn(true)
					selectedCardNode.rotation = 0.0
					selectedCardNode = null
					
					checkStates()
	elif buttonIndex == MOUSE_BUTTON_RIGHT:
		pass
		#if cardNodeToZoneNode[cardNode].zone is InPlayZone:
		#	var inpZoneNode : InPlayNode = cardNodeToZoneNode[cardNode]
		#	if inpZoneNode.cardNodeToButton.has(cardNode):
		#		returningFusionCards = true
		#if not returningFusionCards:
		#	pass
	elif buttonIndex == MOUSE_BUTTON_MIDDLE:
		pass
#		cardNode.flip()
#
#		if cardNodeToInPlayButton.has(cardNode):
#			fuseEndSlot = cardNodeToInPlayButton[cardNode]
#			var index : int = oldDisplay.cardNodes.find(cardNode)
#			removeCardNodeDisplay(cardNode)
#			fuseEndSlot.visible = true
#			setCardNodeDisplay(oldDisplay, fuseEndSlot)
#			oldDisplay.moveCardNode(fuseEndSlot, index)
#			setCardNodeDisplay(fusionDisplay, cardNode)
#			fusionDisplay.moveCardNode(cardNode, 0)
#			cardNodeToInPlayButton.erase(cardNode)
#			fuseInitialWait = 1.0

var cardNodesFusing : Array = []
var fuseInitialWait : float = 0.0
var fuseWaiting : bool = true
var fuseWaitTimer : float = 0.0
var fusing : bool = false
var fuseStartPos : Vector2 = Vector2.ZERO
var fuseEndPos : Vector2 = Vector2.ZERO
var fuseTimer : float = 0.0
var fuseSpinTimer : float = 0.0
var fuseSpinWaitTimer : float = 0.0
var fuseReturnTimer : float = 0
var fuseEndSlot = null
var fuseWasInPlay : bool = false
var returningFusionCards : bool = false

const fuseWaitMaxTime : float = 0.5
const fuseMaxTime : float = 0.1
const fuseSpinMaxTime : float = 0.55
const fuseRPS : float = 2.0
const fuseSpinWaitMaxTime : float = 0.501
const fuseReturnMaxTime : float = 0.3

var isFirstTurn : bool = true
var hasFusedThisTurn : bool = false

var selectedCardNode : CardNode = null
var selectTimer : float = 0.0

var turnArrowTimer : float = 0.0
const turnArrowRPS: float = 3.0

func getFusionHashOffset(cid0 : int, cid1 : int) -> Vector2:
	cid0 += 1
	cid1 += 1
	var hashInt : int = cid0 * cid0 + cid0 + cid1 if cid0 >= cid1 else cid0 + cid1 * cid1
	var rot : float = hashInt * 51.287513957
	return Vector2.RIGHT.rotated(rot)

var aiTimer : float = 0.0

func _process(delta: float) -> void:
	var dAnim = delta * 1.0
	
	if board.activePlayer != board.players[0]:
		aiTimer += delta
		if aiTimer > 1.0:
			simBadAI()
			aiTimer = 0.0
	
	if cardNodesFusing.size() > 0:
		#Pause to allow cards to get into position
		if fuseInitialWait > 0.0:
			fuseInitialWait -= delta
			if fuseInitialWait <= 0.0:
				zoneToNode[board.playerToFusionZone[board.activePlayer]].fusing = true
		#Delay in between fusions
		elif fuseWaiting:
			fuseWaitTimer += dAnim
			if fuseWaitTimer >= fuseWaitMaxTime:
				fuseWaiting = false
		else:
			#Fusing two cards together
			if cardNodesFusing.size() > 1:
				if not fusing:
					fusing = true
					fuseStartPos = cardNodesFusing[1].position
					fuseEndPos = cardNodesFusing[0].position
				if fusing:
					#Collision animation
					if fuseTimer < fuseMaxTime:
						fuseTimer += dAnim
						var deltaPos = cardNodesFusing[1].position
						cardNodesFusing[1].position = lerp(fuseStartPos, fuseEndPos, fuseTimer / fuseMaxTime)
						deltaPos -= cardNodesFusing[1].position
						#for i in range(2, cardNodesFusing.size()):
						#	cardNodesFusing[i].position -= deltaPos
						
						if fuseTimer >= fuseMaxTime:
							var fusionOutput : int = FusionManager.getFusion(cardNodesFusing[0].card, cardNodesFusing[1].card)
							if fusionOutput == FusionManager.FUSION_INVALID or fusionOutput == FusionManager.FUSION_UNCHANGED:
								fuseSpinWaitTimer = fuseSpinWaitMaxTime
								fuseSpinTimer = fuseSpinMaxTime-delta
							else:
								cardNodesFusing[0].flipSame()
								cardNodesFusing[1].flipSame()
					
					#Flip waiting and moving outward
					elif fuseSpinWaitTimer < fuseSpinWaitMaxTime:
						fuseSpinWaitTimer += dAnim
						var v0 : Vector2 = getFusionHashOffset(cardNodesFusing[0].card.cid, cardNodesFusing[1].card.cid)
						var off : Vector2 = v0 * lerp(0.0, ListOfCards.CARD_WIDTH * 1.5, fuseSpinWaitTimer / fuseSpinWaitMaxTime)
						cardNodesFusing[0].position = fuseEndPos - off
						cardNodesFusing[1].position = fuseEndPos + off
					
					#Spinning together
					elif fuseSpinTimer < fuseSpinMaxTime:
						fuseSpinTimer += dAnim
						
						var x = fuseSpinTimer / fuseSpinMaxTime
						var ss
						if x < 0.5:
							ss = 0.5 - sqrt(.25 - x*x)
						else:
							ss = 0.5 + sqrt(.25 - (x-1)*(x-1))
			
						var v0 : Vector2 = getFusionHashOffset(cardNodesFusing[0].card.cid, cardNodesFusing[1].card.cid)
						var off : Vector2 = v0.rotated(fuseSpinTimer / fuseSpinMaxTime * PI * 2 * fuseRPS) * lerp(ListOfCards.CARD_WIDTH* 1.5, 0.0, fuseSpinTimer / fuseSpinMaxTime)
						cardNodesFusing[0].position = fuseEndPos - off
						cardNodesFusing[1].position = fuseEndPos + off
						
						#Calculating fusion
						if fuseSpinTimer >= fuseSpinMaxTime:
							fuseTimer = 0
							fuseSpinTimer = 0
							fuseSpinWaitTimer = 0
							fusing = false
							fuseReturnTimer = 0.0
							var fusionZone = board.getPlayerToFusionZone(board.activePlayer)
							var fusionOutput : int = FusionManager.getFusion(cardNodesFusing[0].card, cardNodesFusing[1].card)
							
							if fusionOutput == FusionManager.FUSION_INVALID:
								var fusingToOpponent : bool = board.activePlayer != cardNodeToZoneNode[fuseEndSlot].zone.player and fuseWasInPlay
								var bumpedCardNode = cardNodesFusing[0]
								var savedCardNode = cardNodesFusing[1]
								if fusingToOpponent:
									bumpedCardNode = cardNodesFusing[1]
									savedCardNode = cardNodesFusing[0]
								#if not fusingToOpponent:
								savedCardNode.desiredPosition = savedCardNode.global_position
								get_tree().create_timer(0.5).connect("timeout", bumpedCardNode.queue_free)
								fusionZone.eraseCard(bumpedCardNode.card)
								cardNodesFusing.erase(bumpedCardNode)
								bumpedCardNode.desiredPosition = cardNodesFusing[0].global_position + Vector2(-100.0, -30.0)
							
							elif fusionOutput == FusionManager.FUSION_UNCHANGED:
								var keepRight : bool = not cardNodesFusing[1].card.creatureTypes.has(Card.CREATURE_TYPE.NULL)
								if not keepRight:
									cardNodesFusing[0].card.attack += cardNodesFusing[1].card.attack
									cardNodesFusing[0].card.health += cardNodesFusing[1].card.health
									cardNodesFusing[0].card.maxHealth += cardNodesFusing[1].card.maxHealth
									cardNodesFusing[0].card.emit_signal("changed")
									cardNodesFusing[1].queue_free()
									fusionZone.removeCard(1)
									cardNodesFusing.remove_at(1)
								else:
									cardNodesFusing[1].card.attack += cardNodesFusing[0].card.attack
									cardNodesFusing[1].card.health += cardNodesFusing[0].card.health
									cardNodesFusing[1].card.maxHealth += cardNodesFusing[0].card.maxHealth
									cardNodesFusing[1].desiredPosition = cardNodesFusing[1].global_position
									cardNodesFusing[1].card.emit_signal("changed")
									cardNodesFusing[0].queue_free()
									fusionZone.removeCard(0)
									cardNodesFusing.remove_at(0)
							else:
								var newCID : int = fusionOutput
								var newCard = ListOfCards.getCard(newCID)
								fusionZone.cards[0] = newCard
								cardNodesFusing[0].setCard(newCard)
								cardNodesFusing[1].queue_free()
								fusionZone.removeCard(1)
								cardNodesFusing.remove_at(1)
							
							fuseWaiting = true
							fuseWaitTimer = 0
							if cardNodesFusing.size() == 1:
								fuseStartPos = cardNodesFusing[0].global_position
			
			#Moving fused card to play
			elif cardNodesFusing.size() == 1:
				if fuseReturnTimer <= fuseReturnMaxTime:
					fuseReturnTimer += dAnim
				else:
					var cardNode = cardNodesFusing[0]
					var inpNode : InPlayNode = getCardNodeToZoneNode(fuseEndSlot)
					var index : int = inpNode.cardNodes.find(fuseEndSlot)
					board.getPlayerToFusionZone(board.activePlayer).removeCard(0)
					fuseEndSlot = null
					cardNodesFusing.clear()
					inpNode.zone.setCard(cardNode.card, index)
					zoneToNode[board.playerToFusionZone[board.activePlayer]].fusing = false
					if isFirstTurn:
						cardNode.setHasAttackedThisTurn(true)
					checkStates()
					fusion_finished.emit()
	
	if selectedCardNode != null:
		selectTimer += delta
		selectedCardNode.rotation = sin(selectTimer * PI/2.0) * PI/40.0
	
	if turnChanging:
		turnJumpTimer += delta
		var t : float = min(1.0, turnJumpTimer/turnJumpMaxTime)
		var pind : int = board.players.find(board.activePlayer)
		var lastRot : float = PI if (pind == 1) else 0.0
		var rot : float = PI if (pind == 0) else 0.0
		turnIndicator.rotation = lerp_angle(lastRot+0.01, rot, t)
		turnIndicator.position.y = -sin(t*PI)*10.0
		if t >= 1.0:
			turnJumpTimer = 0.0
			turnChanging = false
	
	if returningFusionCards:
		returningFusionCards = false
		var cardNodesToReturn : Array = zoneToNode[board.getPlayerToFusionZone(board.activePlayer)].cardNodes.duplicate()
		for cardNode in cardNodesToReturn:
			onCardPressed(MOUSE_BUTTON_LEFT, cardNode)

func onTurnStarted():
	turnChanging = true
	move_camera.emit(1 if board.activePlayer == board.players[0] else -1)
	hasFusedThisTurn = false
	if is_instance_valid(selectedCardNode):
		selectedCardNode.rotation = 0.0
		selectedCardNode = null
	for cardNode in zoneToNode[board.getPlayerToInPlayZone(board.activePlayer)].cardNodes:
		if cardNode != null:
			cardNode.setHasAttackedThisTurn(false)
	if board.activePlayer.hand.cards.size() == 0:
		board.activePlayer.loseGame()
		if board.activePlayer.hand.cards.size() == 0:
			hasFusedThisTurn = true

func playBestFusion(depthMax : int = -1):
	var possibleFusions : Dictionary = {}
	var boardTree : Dictionary = {}
	var doneEmpty : bool = false
	if board.activePlayer.hand.cards.size() == 0:
		return
	for i in range(board.getPlayerToInPlayZone(board.activePlayer).cards.size()):
		var cardInPlay : Card = board.getPlayerToInPlayZone(board.activePlayer).cards[i]
		var adjustedDepthMax : int = depthMax
		if depthMax != -1 and cardInPlay != null:
			adjustedDepthMax += 1
		var tree : Dictionary = board.activePlayer.getFusionsByDepth(adjustedDepthMax, cardInPlay, cardInPlay == null)
		if cardInPlay == null and doneEmpty:
			continue
		if cardInPlay == null:
			doneEmpty = true
		var fusionOut : Array = []
		Player.getBestFusion(tree, fusionOut)
		possibleFusions[cardInPlay] = fusionOut
	var bestStart : Card = null
	for startingCard in possibleFusions.keys():
		if possibleFusions[startingCard][0] == startingCard:
			continue
		if startingCard != null and Card.getBST(possibleFusions[startingCard][0]) < Card.getBST(startingCard):
			continue
		if not possibleFusions.has(bestStart):
			bestStart = startingCard
			continue
		var currentCard : Card = possibleFusions[startingCard][possibleFusions[startingCard].size()-1]
		var compCard : Card = possibleFusions[bestStart][possibleFusions[bestStart].size()-1]
		if currentCard.attack + currentCard.health > compCard.attack + compCard.health:
			bestStart = startingCard
	if bestStart == null and not possibleFusions.has(bestStart):
		#CANNOT PLAY BECAUSE SELF BOARD IS FULL
		pass
	else:
		print("Best Start: " + ("Empty Slot" if bestStart == null else bestStart.name))
		var fString : String = ""
		for i in range(possibleFusions[bestStart].size()):
			if i != possibleFusions[bestStart].size()-1:
				fString += " + "
			else:
				fString += " >> "
			fString += possibleFusions[bestStart][i].name
		print(fString)
		
		for i in range(possibleFusions[bestStart].size()):
			if i != possibleFusions[bestStart].size()-1:
				onCardPressed(MOUSE_BUTTON_LEFT, getCardNode(possibleFusions[bestStart][i]), false)
		if bestStart != null:
			onCardPressed(MOUSE_BUTTON_LEFT, getCardNode(bestStart), false)
		else:
			var playerInpNode : InPlayNode = zoneToNode[board.getPlayerToInPlayZone(board.activePlayer)]
			for i in range(playerInpNode.cardNodes.size()):
				if playerInpNode.cardNodes[i].card == null:
					onCardPressed(MOUSE_BUTTON_LEFT, playerInpNode.cardNodes[i], false)
					break

func simBadAI():
	if cardNodesFusing.size() > 0:
		return
	
	if not hasFusedThisTurn:
		var handZoneNode : HandNode = zoneToNode[board.activePlayer.hand]
		for i in range(handZoneNode.cardNodes.size()-1, -1, -1):
			var cardToFuse : CardNode = handZoneNode.cardNodes[i]
			onCardPressed(MOUSE_BUTTON_LEFT, cardToFuse, false)
		var slotToFuse = null
		var playerInpNode : InPlayNode = zoneToNode[board.getPlayerToInPlayZone(board.activePlayer)]
		for i in range(playerInpNode.cardNodes.size()):
			if playerInpNode.cardNodes[i].card == null:
				slotToFuse = playerInpNode.cardNodes[i]
				break
		if slotToFuse == null:
			var opponentInpNode : InPlayNode = zoneToNode[board.getPlayerToInPlayZone(board.getInactivePlayer())]
			for i in range(opponentInpNode.cardNodes.size()):
				if opponentInpNode.cardNodes[i].card != null:
					slotToFuse = opponentInpNode.cardNodes[i]
					break
		if slotToFuse == null:
			slotToFuse = playerInpNode.cardNodes[0]
			
		onCardPressed(MOUSE_BUTTON_LEFT, slotToFuse, false)
	else:
		var attackerInpNode : InPlayNode = zoneToNode[board.getPlayerToInPlayZone(board.activePlayer)]
		var attackerNodes : Array = []
		for cardNode in attackerInpNode.cardNodes:
			if cardNode.card != null and not cardNode.hasAttackedThisTurn:
				attackerNodes.append(cardNode)
		
		var defenderInpNode : InPlayNode = zoneToNode[board.getPlayerToInPlayZone(board.getInactivePlayer())]
		var defenderNodes : Array = []
		for cardNode in defenderInpNode.cardNodes:
			if cardNode.card != null:
				defenderNodes.append(cardNode)
		
		#Sort attackers and defenders by attack and defense
		
		var attacked : bool = false
		for atkNode : CardNode in attackerNodes:
			var targets : Array = []
			var badTargets : Array = []
			for defNode : CardNode in defenderNodes:
				if atkNode.card.attack >= defNode.card.health:
					if defNode.card.attack >= atkNode.card.health:
						badTargets.append(defNode)
					else:
						targets.append(defNode)
			if defenderNodes.size() == 0:
				targets.append(defenderInpNode.cardNodes[0])
			if targets.size() > 0 or badTargets.size() > 0:
				onCardPressed(MOUSE_BUTTON_LEFT, atkNode, false)
				onCardPressed(MOUSE_BUTTON_LEFT, targets[0] if targets.size() > 0 else badTargets[0], false)
				attacked = true
				break
		if not attacked:
			playerPassTurn(false)

func playerPassTurn(sendToServer : bool = true):
	if gameIsOver:
		return
	if not hasFusedThisTurn:
		return
	if cardNodesFusing.size() != 0:
		return
	var fromServer : bool = not sendToServer
	if board.activePlayer != board.players[0] and not fromServer:
		return
	board.turnEnd()
	if sendToServer:
		turn_passed.emit()
	isFirstTurn = false
