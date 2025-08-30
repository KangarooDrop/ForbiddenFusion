extends Node

const FUSION_INVALID : int = -1
const FUSION_UNCHANGED : int = -2

const uuidEqual = "UUID_equal"
const atkLess = "atk_less"
const atkMore = "atk_more"
const hthLess = "hth_less"
const thtMore = "hth_more"
const atkEqHth = "atk_eq_hth"
const typesContains = "types_contain"
const tagsContains = "tags_cotain"

var fusionMat : Array = []
var fusionRules : Dictionary = {}

#Rules: UUID=, atk<, atk>, hth<, hth>, atk=hth, types_contain, tags_contain
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
		if fCreature.UUID == card0.UUID or fCreature.UUID == card1.UUID:
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
		
		validFusions.append(ListOfCards.cardList[i].UUID)
	
	#No valid fusions
	if validFusions.size() == 0:
		if card0.creatureTypes.has(Card.CREATURE_TYPE.NULL) or card1.creatureTypes.has(Card.CREATURE_TYPE.NULL):
			return FUSION_UNCHANGED
		else:
			return FUSION_INVALID
	
	#Determining weakest possible card
	var lowestUUID : int = FUSION_INVALID
	var lowestScore : int = 0
	for i in range(validFusions.size()):
		var score : int = ListOfCards.cardList[validFusions[i]].attack + ListOfCards.cardList[validFusions[i]].health
		if lowestUUID == FUSION_INVALID or score < lowestScore:
			lowestUUID = validFusions[i]
			lowestScore = score
	
	return lowestUUID

func addFusionRule(outputUUID : int, rules : Dictionary):
	if not fusionRules.has(outputUUID):
		fusionRules[outputUUID] = []
	fusionRules[outputUUID].append(fusionRules)

func setSize(numCards : int):
	fusionMat.clear()
	for x in range(numCards):
		fusionMat.append([])
		for y in range(numCards):
			fusionMat[x].append(FUSION_INVALID)
