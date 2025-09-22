extends RefCounted

class_name Board

var players : Array = []
var numSlots : int = 4
const handSize : int = 5
var playerToFusionZone : Dictionary = {}
var playerToInPlayZone : Dictionary = {}

signal turn_started()

func getInactivePlayer() -> Player:
	for p in players:
		if p != activePlayer:
			return p
	return activePlayer

func getOpponent(player : Player) -> Player:
	var opponentIndex : int = (players.find(player) + 1) % players.size()
	return players[opponentIndex]

func getPlayerToFusionZone(player : Player):
	if not playerToFusionZone.has(player):
		return null
	return playerToFusionZone[player]

func getPlayerToInPlayZone(player : Player):
	if not playerToInPlayZone.has(player):
		return null
	return playerToInPlayZone[player]

func _init(numPlayers : int) -> void:
	for i in range(numPlayers):
		addPlayer(Player.new())

func addPlayer(player : Player):
	players.append(player)
	var inPlayZone : InPlayZone = InPlayZone.new()
	inPlayZone.setNumSlots(numSlots)
	inPlayZone.setPlayer(player)
	playerToInPlayZone[player] = inPlayZone
	var fusionZone : FusionZone = FusionZone.new()
	fusionZone.setPlayer(player)
	playerToFusionZone[player] = fusionZone

func setSlot(player : Player, index : int, card : Card):
	var inPlayZone : InPlayZone = getPlayerToInPlayZone(player)
	if inPlayZone == null:
		return
	if index < 0 or index >= numSlots:
		return
	inPlayZone.setCard(card, index)

func removeSlot(player : Player, index : int):
	var inPlayZone : InPlayZone = getPlayerToInPlayZone(player)
	if inPlayZone == null:
		return
	inPlayZone.removeCard(index)

func removeCreature(card : Card):
	for player in players:
		var inPlayZone : InPlayZone = getPlayerToInPlayZone(player)
		for i in range(numSlots):
			if inPlayZone.cards[i] == card:
				removeSlot(player, i)
				break

func getAllCreatures() -> Array:
	var rtn : Array = []
	for player in players:
		rtn += getCreatureByPlayer(player)
	return rtn

func getCreatureByPlayer(player : Player) -> Array:
	if not players.has(player):
		return []
	
	var rtn : Array = []
	var inPlayZone : InPlayZone = getPlayerToInPlayZone(player)
	for slot in inPlayZone.cards:
		if slot != null:
			rtn.append(slot)
	return rtn

####################################################################################################

func serialize() -> Dictionary:
	var rtn : Dictionary = {"meta":{"activePlayer":players.find(activePlayer)}}
	for playerIndex in range(players.size()):
		#var otherPlayerIndex : int = (i+1) % players.size()
		rtn[playerIndex] = {}
		for zoneIndex : int in [Zone.ZONE_HAND, Zone.ZONE_DECK, Zone.ZONE_IN_PLAY, Zone.ZONE_FUSION]:
			rtn[playerIndex][zoneIndex] = []
			var zone : Zone
			if zoneIndex == Zone.ZONE_HAND:
				zone = players[playerIndex].hand
			elif zoneIndex == Zone.ZONE_DECK:
				zone = players[playerIndex].deck
			elif zoneIndex == Zone.ZONE_IN_PLAY:
				zone = getPlayerToInPlayZone(players[playerIndex])
			elif zoneIndex == Zone.ZONE_FUSION:
				zone = getPlayerToFusionZone(players[playerIndex])
			for card in zone.cards:
				rtn[playerIndex][zoneIndex].append(card.serialize() if card != null else null)
	return rtn

func deserialize(data : Dictionary) -> void:
	for key in data.keys():
		if not typeof(key) == TYPE_INT:
			continue
		var playerIndex : int = key
		for zoneIndex : int in [Zone.ZONE_HAND, Zone.ZONE_DECK, Zone.ZONE_IN_PLAY, Zone.ZONE_FUSION]:
			if zoneIndex == Zone.ZONE_HAND:
				players[playerIndex].hand.setDataSerialized(data[playerIndex][zoneIndex])
			elif zoneIndex == Zone.ZONE_DECK:
				players[playerIndex].deck.setDataSerialized(data[playerIndex][zoneIndex])
			elif zoneIndex == Zone.ZONE_IN_PLAY:
				getPlayerToInPlayZone(players[playerIndex]).setDataSerialized(data[playerIndex][zoneIndex])
			elif zoneIndex == Zone.ZONE_FUSION:
				getPlayerToFusionZone(players[playerIndex]).setDataSerialized(data[playerIndex][zoneIndex])
	activePlayer = players[data["meta"]["activePlayer"]]
	emit_signal("turn_started")

####################################################################################################

func startGame():
	for player in players:
		fillHand(player)
	var startingIndex : int = randi() % players.size()
	turnStart(players[startingIndex])

func fillHand(player : Player):
	var cardsInHand : int = player.hand.cards.size()
	player.deck.draw(handSize - cardsInHand)

var activePlayer : Player = null
func turnStart(player : Player):
	activePlayer = player
	emit_signal("turn_started")

func onCardsPlayed(slotIndex, cards : Array):
	pass

func turnEnd():
	fillHand(activePlayer)
	var nextIndex : int = (players.find(activePlayer) + 1) % players.size()
	turnStart(players[nextIndex])
