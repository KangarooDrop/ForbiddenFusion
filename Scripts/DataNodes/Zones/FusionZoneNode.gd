extends ZoneNode

class_name FusionZoneNode

var fusing : bool = false

func initModes() -> void:
	setSeenMode(SEEN_MODE.INHERITED)
	setOffsetMode(OFF_MODE.ROW_WIDE)

func _process(delta: float) -> void:
	if not fusing:
		super._process(delta)
