extends PlayerRankNode

const SHRUNK_HEIGHT_ONE : float = 144.0
const EXPAND_HEIGHT_ONE : float = 144.0+32.0

func getShrunkenHeight() -> float:
	return SHRUNK_HEIGHT_ONE
func getExpandHeight() -> float:
	return EXPAND_HEIGHT_ONE

func getPlayerPortrait():
	return $Header/PlayerPortraitHolder/PlayerPortrait

func getFightButton():
	return $FightButton

func getType0Sprite() -> Sprite2D:
	return $Type0Holder/Sprite2D
func getType1Sprite() -> Sprite2D:
	return $Type1Holder/Sprite2D

func setPlayerRank(newPlayerRank : int):
	playerRank = newPlayerRank
