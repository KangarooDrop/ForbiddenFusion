extends Node2D

var fusionVisNodePacked : PackedScene = preload("res://Scenes/FusionVisualizer/FusionVisNode.tscn")

var cards : Array = []
var cardToVis : Dictionary = {}

@onready var cam : Camera2D = $Camera2D

func _ready() -> void:
	var cidToCard : Dictionary = {}
	var w : int = ceil(sqrt(ListOfCards.cardList.size()))
	#var tiers : Array = []
	for i in range(ListOfCards.cardList.size()):
		var card : Card = ListOfCards.getCard(i)
		cards.append(card)
		cidToCard[card.cid] = card
		
		var fvn : FusionVisNode = fusionVisNodePacked.instantiate()
		add_child(fvn)
		fvn.cardNode.pressed.connect(self.onCardNodePressed.bind(fvn))
		fvn.cardNode.setCard(card)
		fvn.position = Vector2(w*randf(), w*randf()) * Vector2(ListOfCards.CARD_SIZE) * 5.0
		cardToVis[card] = fvn
	
	for i in range(cards.size()):
		var c0 : Card = cards[i]
		for j in range(cards.size()):
			var c1 : Card = cards[j]
			var output : int = FusionManager.getFusion(c0, c1)
			if output >= 0:
				cardToVis[c0].addOutput(cardToVis[cards[output]])
				#print(str(i), " ", str(j), " -->> ", output)

var heldFVN = null
func onCardNodePressed(buttonIndex : int, fvn : FusionVisNode):
	if buttonIndex == MOUSE_BUTTON_LEFT:
		if fvn == heldFVN:
			heldFVN = null
		else:
			heldFVN = fvn

func _process(delta: float) -> void:
	if is_instance_valid(heldFVN):
		heldFVN.global_position = get_global_mouse_position()
	
	for cn0 in cardToVis.values():
		for cn1 in cardToVis.values():
			if cn0 == cn1:
				continue
			
			var dp : Vector2 = cn0.global_position - cn1.global_position
			var md : float = 400.0
			if cn0.getOutputs().has(cn1) or cn1.getOutputs().has(cn0):
				var mv : Vector2 = (dp.length()-md) * dp.normalized()
				cn1.position += mv * delta * 0.5
			elif dp.length() < 500.0:
				cn1.position += -dp.normalized() * pow(500.0/dp.length(), 2.0) * delta

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode == KEY_W:
			cam.position.y -= 10
		elif event.keycode == KEY_S:
			cam.position.y += 10
		elif event.keycode == KEY_A:
			cam.position.x -= 10
		elif event.keycode == KEY_D:
			cam.position.x += 10
