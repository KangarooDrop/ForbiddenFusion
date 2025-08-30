extends Node2D

class_name CardDisplay

var cardNodes : Array = []
var moveQueueSize : int = 0
const QUEUE_DELAY : float = 0.05

@export var seenMode : SEEN_MODE = SEEN_MODE.INHERITED
func setSeenMode(newSeenMode):
		self.seenMode = newSeenMode
		if seenMode == SEEN_MODE.SEEN:
			flipAllToFront()
		elif seenMode == SEEN_MODE.CONCEALED:
			flipAllToBack()
enum SEEN_MODE {INHERITED, SEEN, CONCEALED}

@export var offsetMode : OFF_MODE = OFF_MODE.ROW_WIDE
func setOffsetMode(newOffsetMode):
		self.offsetMode = newOffsetMode
		if newOffsetMode == OFF_MODE.ROW_NARROW:
			offset = Vector2i(OFF_HORZ_NARROW, 0)
		elif newOffsetMode == OFF_MODE.ROW_WIDE:
			offset = Vector2i(OFF_HORZ_WIDE, 0)
		elif newOffsetMode == OFF_MODE.PILE_NARROW:
			offset = Vector2i(0, OFF_VERT_NARROW)
var offset : Vector2 = Vector2.ZERO
enum OFF_MODE {ROW_NARROW, ROW_WIDE, PILE_NARROW}

const OFF_HORZ_NARROW : int = 6
const OFF_HORZ_WIDE : int = ListOfCards.CARD_WIDTH + 4
const OFF_VERT_NARROW : int = -2

func _ready() -> void:
	setSeenMode(seenMode)
	setOffsetMode(offsetMode)

func addCardNode(cardNode : CardNode):
	cardNodes.append(cardNode)
	if seenMode == SEEN_MODE.SEEN and not cardNode.isSeen:
		cardNode.flip()
	elif seenMode == SEEN_MODE.CONCEALED and cardNode.isSeen:
		cardNode.flip()
	cardNode.moveDelay = QUEUE_DELAY * moveQueueSize
	moveQueueSize += 1

func moveCardNode(cardNode : CardNode, index : int):
	cardNodes.erase(cardNode)
	cardNodes.insert(index, cardNode)

func removeCardNode(index : int):
	if index < 0 or index >= cardNodes.size():
		return
	cardNodes[index].desiredPosition = null
	cardNodes.remove_at(index)

func eraseCardNode(cardNode : CardNode):
	removeCardNode(cardNodes.find(cardNode))

func setIsSeen(newIsSeen : bool) -> void:
	for cn : CardNode in cardNodes:
		cn.setIsSeen(newIsSeen)

func flipAllToFront() -> void:
	for cn : CardNode in cardNodes:
		if not cn.isSeen:
			cn.flip()

func flipAllToBack() -> void:
	for cn : CardNode in cardNodes:
		if cn.isSeen:
			cn.flip()

func shuffleCards():
	cardNodes.shuffle()

func _process(delta: float) -> void:
	moveQueueSize = 0
	for i in range(cardNodes.size()):
		var d : float = float(i)
		if offsetMode != OFF_MODE.PILE_NARROW:
			d -= (cardNodes.size()-1.0)/2.0
		cardNodes[i].desiredPosition = global_position + offset * d
