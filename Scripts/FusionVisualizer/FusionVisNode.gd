extends Node2D

class_name FusionVisNode

@onready var cardNode : CardNode = $CardNode

func _ready() -> void:
	cardNode.setIsSeen(true)

var visNodeToLines : Dictionary = {}
func addOutput(visNode : FusionVisNode) -> void:
	var line0 : Line2D = Line2D.new()
	line0.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	line0.width = 80
	#var wCurve : Curve = Curve.new()
	#wCurve.add_point(Vector2.UP)
	#wCurve.add_point(Vector2.RIGHT)
	#line0.width_curve = wCurve
	line0.default_color = Card.getCreatureTypeToColor(int(cardNode.card.creatureTypes[0]))
	line0.default_color.a = 0.25
	add_child(line0)
	
	var line1 : Line2D = Line2D.new()
	line1.points = PackedVector2Array([Vector2.ZERO, Vector2.ZERO])
	line1.width = 2
	line1.default_color = Color.BLACK
	add_child(line1)
	
	visNodeToLines[visNode] = [line0, line1]

func getOutputs() -> Array:
	return visNodeToLines.keys()

func _process(delta: float) -> void:
	for visNode in visNodeToLines.keys():
		var dp : Vector2 = visNode.global_position - global_position
		visNodeToLines[visNode][0].points[1] = dp
		visNodeToLines[visNode][1].points[1] = dp
