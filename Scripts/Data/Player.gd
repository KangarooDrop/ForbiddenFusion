extends RefCounted

class_name Player

var health : int = 40
var deck : Deck
var hand : Hand
var board : Board

var playerUUID : int = -1

signal before_game_loss()
signal after_game_loss()
signal before_health_change(amountPointer : Array)
signal after_health_change(amountPointer : Array)

func setBoard(newBoard : Board):
	self.board = newBoard

func _init() -> void:
	deck = Deck.new()
	deck.setPlayer(self)
	hand = Hand.new()
	hand.setPlayer(self)

func setHealth(amount : int):
	var amountPointer : Array = [amount]
	emit_signal("before_health_change", amountPointer)
	health = amount
	emit_signal("after_health_change", amountPointer)
	
	if health <= 0:
		loseGame()

func addHealth(amount : int):
	var newVal : int = health + amount
	setHealth(newVal)

func loseGame(isConcede : bool = false):
	if not isConcede:
		emit_signal("before_game_loss")
		if health > 0 and (hand.cards.size() > 0 or deck.cards.size() > 0):
			return
	emit_signal("after_game_loss")

####################################################################################################

func getFusionsByDepth(maxDepth : int, fusingTo : Card = null, allowBumping : bool = false) -> Dictionary:
	return getFusionTree(hand.cards.duplicate(), fusingTo, maxDepth, 0, allowBumping)

func getFusionTree(cards : Array = hand.cards.duplicate(), fusingTo : Card = null, maxDepth : int = -1, currentDepth : int = 0, allowBumping : bool = false) -> Dictionary:
	var rtn : Dictionary = {}
	if maxDepth != -1 and currentDepth >= maxDepth:
		pass
	else:
		for card in cards:
			if fusingTo == null:
				var newCards : Array = cards.duplicate()
				newCards.erase(card)
				var childTree = getFusionTree(newCards, card, maxDepth, currentDepth+1)
				if not childTree.is_empty():
					rtn[card] = childTree
			else:
				var fusionOutput : int = FusionManager.getFusion(fusingTo, card)
				if fusionOutput == FusionManager.FUSION_INVALID:
					if not allowBumping:
						continue
					var newCards : Array = cards.duplicate()
					newCards.erase(card)
					rtn[card] = getFusionTree(newCards, card, maxDepth, currentDepth+1)
				elif fusionOutput == FusionManager.FUSION_UNCHANGED:
					#continue
					var keepRight : bool = fusingTo.creatureTypes.has(Card.CREATURE_TYPE.NULL)
					var newCard : Card
					var otherCard : Card
					if keepRight:
						newCard = card.duplicate()
						otherCard = fusingTo.duplicate()
					else:
						newCard = fusingTo.duplicate()
						otherCard = card.duplicate()
					newCard.attack += otherCard.attack
					newCard.health += otherCard.health
					newCard.maxHealth += otherCard.maxHealth
					
					var newCards : Array = cards.duplicate()
					newCards.erase(card)
					var ft = getFusionTree(newCards, newCard, maxDepth, currentDepth+1)
					ft["out"] = newCard
					rtn[card] = ft
				else:
					var newCID : int = fusionOutput
					var newCard : Card = ListOfCards.getCard(newCID)
					var newCards : Array = cards.duplicate()
					newCards.erase(card)
					var ft = getFusionTree(newCards, newCard, maxDepth, currentDepth+1)
					ft["out"] = newCard
					rtn[card] = ft
	
	if rtn.is_empty():
		rtn["out"] = fusingTo
	return rtn

static func getBestFusion(tree : Dictionary, bestLineOut : Array, currentLine : Array = []):
	for key in tree.keys():
		if typeof(key) == TYPE_STRING:
			var isBetter : bool = bestLineOut.size() == 0
			if not isBetter:
				if tree[key].attack + tree[key].health >= bestLineOut[bestLineOut.size()-1].attack + bestLineOut[bestLineOut.size()-1].health:
					if currentLine.size() <= bestLineOut.size():
						isBetter = true
			if isBetter:
				bestLineOut.clear()
				bestLineOut.append_array(currentLine + [tree[key]])
		else:
			getBestFusion(tree[key], bestLineOut, currentLine + [key])

static func printFusionTree(tree : Dictionary, buffer : String = "", currentBestPointer = [Vector2i.ZERO], currentDepth : int = 0):
	var string : String = ""
	for key in tree.keys():
		if typeof(key) == TYPE_STRING:
			var isBetter : bool = tree[key].attack + tree[key].health >= currentBestPointer[0].x + currentBestPointer[0].y
			if isBetter:
				currentBestPointer[0].x = tree[key].attack
				currentBestPointer[0].y = tree[key].health
				var atkHth : String = str(tree[key].attack) + "/" + str(tree[key].health)
				print("  [" + atkHth + "] " + "*".repeat(currentDepth) + buffer + "    >> ", tree[key].name + " (" + atkHth + ")" + " ???  " + str(currentBestPointer[0]))
		else:
			printFusionTree(tree[key], (buffer + " | " if not buffer.is_empty() else " ") + key.name, currentBestPointer, currentDepth + 1)

func getBumpTree(cards : Array = hand.cards.duplicate(), fusingFrom : Card = null, maxDepth : int = -1, currentDepth : int = 0) -> Dictionary:
	var rtn : Dictionary = {}
	if maxDepth != -1 and currentDepth >= maxDepth:
		pass
	else:
		for newCard in cards:
			if fusingFrom == null:
				var newCards : Array = cards.duplicate()
				newCards.erase(newCard)
				rtn[newCard] = getBumpTree(newCards, newCard, maxDepth, currentDepth + 1)
			else:
				var fusionOutput : int = FusionManager.getFusion(newCard, fusingFrom)
				if fusionOutput == FusionManager.FUSION_INVALID:
					var newCards : Array = cards.duplicate()
					newCards.erase(newCard)
					rtn[newCard] = getBumpTree(newCards, newCard, maxDepth, currentDepth + 1)
	if rtn.is_empty():
		rtn["out"] = fusingFrom
	return rtn

static func printBumpTree(tree : Dictionary, buffer : String = "", currentDepth : int = 0):
	var string : String = ""
	for key in tree.keys():
		if typeof(key) == TYPE_STRING:
			print("*".repeat(currentDepth) + buffer + "    >> ", tree[key].name)
		else:
			printBumpTree(tree[key], (buffer + " | " if not buffer.is_empty() else " ") + key.name, currentDepth + 1)
