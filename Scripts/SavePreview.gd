extends Node2D

@onready var nameLabel : Label = $NameLabel
@onready var rankLabel : Label = $RankLabel
@onready var playerPortrait : PlayerPortrait = $PlayerPortraitHolder/PlayerPortrait
@onready var type0Sprite : Sprite2D = $Type0Holder/Sprite2D
@onready var type1Sprite : Sprite2D = $Type1Holder/Sprite2D

func setPlayerData() -> void:
	#Locating user player data
	var saveData : Dictionary = FileIO.getSaveData()
	var playerData : Dictionary = {}
	for playerUUID in saveData.keys():
		if saveData[playerUUID]["is_user"]:
			playerData = saveData[playerUUID]
			break
	if playerData.is_empty():
		return
	
	#Setting player portrait
	playerPortrait.deserialize(playerData['player_data'])
	
	#Setting player name
	nameLabel.text = playerData["player_name"]
	
	#Setting player rank
	rankLabel.text = "#" + str(playerData["player_rank"])
	
	#Setting type indicators
	var deckData : Dictionary = playerData["deck_data"]
	var mostCommonTypes : Array = Util.getMostCommonTypes(deckData)
	type0Sprite.region_rect.position.x = mostCommonTypes[0] * 8.0
	if mostCommonTypes.size() == 1:
		type1Sprite.hide()
	else:
		type1Sprite.region_rect.position.x = mostCommonTypes[1] * 8.0
		type1Sprite.show()
