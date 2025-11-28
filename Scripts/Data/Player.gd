extends RefCounted

class_name Player

var health : int = 40
var deck : Deck
var hand : Hand
var board : Board

var playerUUID : int = -1
var playerRank : int = -1

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

func setPlayerUUID(newPlayerUUID : int) -> void:
	self.playerUUID = newPlayerUUID
	deck.setData(DeckEditor.getSaveDeck(newPlayerUUID))
	
	var saveData : Dictionary = FileIO.getSaveData()
	self.playerRank = saveData[newPlayerUUID]["player_rank"]

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
				var childTree = getFusionTree(newCards, card, maxDepth, currentDepth+1, allowBumping)
				if not childTree.is_empty():
					rtn[card] = childTree
			else:
				var fusionOutput : int = FusionManager.getFusion(fusingTo, card)
				if fusionOutput == FusionManager.FUSION_INVALID:
					if not allowBumping:
						continue
					var newCards : Array = cards.duplicate()
					newCards.erase(card)
					rtn[card] = getFusionTree(newCards, card, maxDepth, currentDepth+1, allowBumping)
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
					var ft = getFusionTree(newCards, newCard, maxDepth, currentDepth+1, allowBumping)
					ft["out"] = newCard
					rtn[card] = ft
				else:
					var newCID : int = fusionOutput
					var newCard : Card = ListOfCards.getCard(newCID)
					var newCards : Array = cards.duplicate()
					newCards.erase(card)
					var ft = getFusionTree(newCards, newCard, maxDepth, currentDepth+1, allowBumping)
					ft["out"] = newCard
					rtn[card] = ft
	
	if rtn.is_empty():
		rtn["out"] = fusingTo
	return rtn

func getAllFusions(fusingTo : Card = null, isOpponent : bool = false, maxDepth : int = -1) -> Array:
	#print(FusionManager.getFusionCardResult(hand.cards[0], hand.cards[1], false))
	var out : Array = []
	getAllFusionsRecursive(out, hand.cards.duplicate(), fusingTo, isOpponent, isOpponent and fusingTo != null, maxDepth)
	for line : Array in out:
		line.insert(0, not isOpponent)
	return out

func getAllFusionsRecursive(out : Array, cards : Array, fusingTo : Card, isOpponent : bool, noBump : bool, maxDepth : int, currentLine : Array = []) -> void:
	if currentLine.size() > 0:
		out.append(currentLine + [fusingTo])
	else:
		currentLine.append(fusingTo)
	if (maxDepth != -1 and currentLine.size() >= maxDepth+1) or cards.size() == 0:
		return
	
	for card : Card in cards:
		if fusingTo == null:
			var newCards : Array = cards.duplicate()
			newCards.erase(card)
			getAllFusionsRecursive(out, newCards, card, isOpponent, noBump, maxDepth, currentLine + [card])
		else:
			var fusedCard : Card = FusionManager.getFusionCardResult(fusingTo, card, noBump)
			#First fusion results in a bump (e.g. Ignore fusions that start invalid)
			if currentLine.size() == 1 and FusionManager.getFusion(fusingTo, card) == FusionManager.FUSION_INVALID and not noBump:
				continue
			
			var newCards : Array = cards.duplicate()
			newCards.erase(card)
			getAllFusionsRecursive(out, newCards, fusedCard, isOpponent, noBump, maxDepth, currentLine + [card])

#score = BST * 10 - cardsUsed
static func evalScore(fusionLine : Array) -> int:
	if fusionLine[0]:
		var startCard : Card = fusionLine[1]
		var endCard : Card = fusionLine[fusionLine.size()-1]
		var endBST : int = endCard.attack + endCard.health
		var numCards : int = fusionLine.size()-3
		if startCard == null:
			return endBST * 10 - numCards
		else:
			var startBST : int = startCard.attack + startCard.health
			return (endBST - startBST) * 10 - numCards
	else:
		var startCard : Card = fusionLine[1]
		var endCard : Card = fusionLine[fusionLine.size()-1]
		var endBST : int = endCard.attack + endCard.health
		if startCard == null:
			return -endBST * 10
		else:
			var startBST : int = startCard.attack + startCard.health
			var numCards : int = fusionLine.size()-3
			return (startBST - endBST) * 10 - numCards

static func sortAllFusion(fusionLinesArray : Array) -> Array:
	var unsorted : Array = fusionLinesArray.duplicate()
	var sorted : Array = []
	while unsorted.size() > 0:
		var highestScore : int = Util.INT_MIN
		var highestIndex : int = -1
		var lowestDepth : int = Util.INT_MAX
		for i in range(unsorted.size()):
			var currentScore : int = evalScore(unsorted[i])
			var currentDepth : int = unsorted[i].size()-1
			if highestIndex == -1 or \
					currentScore > highestScore or \
					(currentScore == highestScore and currentDepth < lowestDepth):
				highestScore = currentScore
				highestIndex = i
				lowestDepth = currentDepth
		if highestScore < -2 and sorted.size() > 0:
			break
		sorted.append(unsorted[highestIndex])
		unsorted.remove_at(highestIndex)
	return sorted

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
	for key in tree.keys():
		if typeof(key) == TYPE_STRING:
			print("*".repeat(currentDepth) + buffer + "    >> ", tree[key].name)
		else:
			printBumpTree(tree[key], (buffer + " | " if not buffer.is_empty() else " ") + key.name, currentDepth + 1)
