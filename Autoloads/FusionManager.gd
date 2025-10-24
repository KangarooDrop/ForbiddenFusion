extends Node

const FUSION_INVALID : int = -1
const FUSION_UNCHANGED : int = -2

const cidEqual = "cid_equal"
const atkLess = "atk_less"
const atkMore = "atk_more"
const hthLess = "hth_less"
const thtMore = "hth_more"
const atkEqHth = "atk_eq_hth"
const typesContains = "types_contain"
const tagsContains = "tags_cotain"

var fusionMat : Array = []

#Rules: cid=, atk<, atk>, hth<, hth>, atk=hth, types_contain, tags_contain
func getFusion(card0 : Card, card1 : Card) -> int:
	#Null Cards
	if (card0.creatureTypes.has(Card.CREATURE_TYPE.NULL) and card0.creatureTypes.size() == 1) or \
			(card1.creatureTypes.has(Card.CREATURE_TYPE.NULL) and card1.creatureTypes.size() == 1):
		return FUSION_UNCHANGED
	
	#Fusing
	var statTotal : Vector2i = Vector2i.ZERO
	statTotal.x = max(card0.attack, card1.attack)
	statTotal.y = max(card0.health, card1.health)
	var creatureTypesTotal : Array = []
	for ct in card0.creatureTypes + card1.creatureTypes:
		if not creatureTypesTotal.has(ct):
			creatureTypesTotal.append(ct)
	var validFusions : Array = []
	for i in range(ListOfCards.cardList.size()):
		var fCreature : Card = ListOfCards.cardList[i]
		if fCreature.cid == card0.cid or fCreature.cid == card1.cid:
			continue
		if fCreature.rarity == Card.RARITY.BASIC:
			continue
		if fCreature.attack < statTotal.x:
			continue
		if fCreature.health < statTotal.y:
			continue
		if fCreature.attack == statTotal.x and fCreature.health == statTotal.y:
			continue
		
		#The fusion creature's types can differ from the total creature types by no more than 1 
		var ctDistTotal : int = Card.getCreatureTypeDist(fCreature.creatureTypes, creatureTypesTotal)
		if ctDistTotal > 1:
			continue
		
		#If the fusion creature shares no types with either card: continue
		var ctShared0 : int = Card.getCreatureTypesShared(fCreature.creatureTypes, card0.creatureTypes)
		var ctShared1 : int = Card.getCreatureTypesShared(fCreature.creatureTypes, card1.creatureTypes)
		if ctShared0 < 1 or ctShared1 < 1:
			continue
		
		#If the fusion creature's types is not a subset of the total creature types: continue
		var ctSharedTotal : int = Card.getCreatureTypesShared(fCreature.creatureTypes, creatureTypesTotal)
		if ctSharedTotal < fCreature.creatureTypes.size():
			continue
		
		"""
		if fCreature.creatureTypes.size() > creatureTypesTotal.size():
			continue
		if not fCreature.creatureTypes.has(card1.creatureTypes[0]):
			if card1.creatureTypes.size() == 1 or not fCreature.creatureTypes.has(card1.creatureTypes[1]):
				continue
		"""
		
		validFusions.append(ListOfCards.cardList[i].cid)
	
	#No valid fusions
	if validFusions.size() == 0:
		if card0.creatureTypes.has(Card.CREATURE_TYPE.NULL) or card1.creatureTypes.has(Card.CREATURE_TYPE.NULL):
			return FUSION_UNCHANGED
		else:
			return FUSION_INVALID
	
	#Determining weakest possible card
	var lowestCID : int = FUSION_INVALID
	var lowestScore : int = 0
	for i in range(validFusions.size()):
		var score : int = ListOfCards.cardList[validFusions[i]].attack + ListOfCards.cardList[validFusions[i]].health
		if lowestCID == FUSION_INVALID or score < lowestScore:
			lowestCID = validFusions[i]
			lowestScore = score
	
	return lowestCID

func getFusionCardResult(card0 : Card, card1 : Card, isOpponent : bool) -> Card:
	return applyFusionOutput(card0.duplicate(), card1.duplicate(), isOpponent)

#If invalid: Returns card1
#If null fusion: Returns card reference with adjusted stats
#If valid: Returns new card
func applyFusionOutput(card0 : Card, card1 : Card, isOpponent : bool) -> Card:
	#Fusing
	var statTotal : Vector2i = Vector2i.ZERO
	statTotal.x = max(card0.attack, card1.attack)
	statTotal.y = max(card0.health, card1.health)
	var creatureTypesTotal : Array = []
	for ct in card0.creatureTypes + card1.creatureTypes:
		if not creatureTypesTotal.has(ct):
			creatureTypesTotal.append(ct)
	var validFusions : Array = []
	for i in range(ListOfCards.cardList.size()):
		var fCreature : Card = ListOfCards.cardList[i]
		if fCreature.cid == card0.cid or fCreature.cid == card1.cid:
			continue
		if fCreature.rarity == Card.RARITY.BASIC:
			continue
		if fCreature.attack < statTotal.x:
			continue
		if fCreature.health < statTotal.y:
			continue
		if fCreature.attack == statTotal.x and fCreature.health == statTotal.y:
			continue
		
		#The fusion creature's types can differ from the total creature types by no more than 1 
		var ctDistTotal : int = Card.getCreatureTypeDist(fCreature.creatureTypes, creatureTypesTotal)
		if ctDistTotal > 1:
			continue
		
		#If the fusion creature shares no types with either card: continue
		var ctShared0 : int = Card.getCreatureTypesShared(fCreature.creatureTypes, card0.creatureTypes)
		var ctShared1 : int = Card.getCreatureTypesShared(fCreature.creatureTypes, card1.creatureTypes)
		if ctShared0 < 1 or ctShared1 < 1:
			continue
		
		#If the fusion creature's types is not a subset of the total creature types: continue
		var ctSharedTotal : int = Card.getCreatureTypesShared(fCreature.creatureTypes, creatureTypesTotal)
		if ctSharedTotal < fCreature.creatureTypes.size():
			continue
		
		"""
		if fCreature.creatureTypes.size() > creatureTypesTotal.size():
			continue
		if not fCreature.creatureTypes.has(card1.creatureTypes[0]):
			if card1.creatureTypes.size() == 1 or not fCreature.creatureTypes.has(card1.creatureTypes[1]):
				continue
		"""
		
		validFusions.append(ListOfCards.cardList[i].cid)
	
	#No valid fusions
	if validFusions.size() == 0:
		if card0.creatureTypes.has(Card.CREATURE_TYPE.NULL) or card1.creatureTypes.has(Card.CREATURE_TYPE.NULL):
			#Apply null buffs
			if card1.creatureTypes.has(Card.CREATURE_TYPE.NULL):
				card0.attack += card1.attack
				card0.health += card1.health
				card0.maxHealth += card1.maxHealth
				card0.emit_signal("changed")
				return card0
			else:
				card1.attack += card0.attack
				card1.health += card0.health
				card1.maxHealth += card0.maxHealth
				card1.emit_signal("changed")
				return card1
		else:
			if isOpponent:
				return card0
			else:
				return card1
	
	#Determining weakest possible card
	var lowestCID : int = FUSION_INVALID
	var lowestScore : int = 0
	for i in range(validFusions.size()):
		var score : int = ListOfCards.cardList[validFusions[i]].attack + ListOfCards.cardList[validFusions[i]].health
		if lowestCID == FUSION_INVALID or score < lowestScore:
			lowestCID = validFusions[i]
			lowestScore = score
	
	return ListOfCards.getCard(lowestCID)
