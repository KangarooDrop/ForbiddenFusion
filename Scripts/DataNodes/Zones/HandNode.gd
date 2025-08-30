extends ZoneNode

class_name HandNode

func initModes() -> void:
	setSeenMode(SEEN_MODE.CONCEALED)
	setOffsetMode(OFF_MODE.ROW_WIDE)

func setHand(newHand : Hand):
	setZone(newHand)
