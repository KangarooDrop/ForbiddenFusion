extends Zone

class_name FusionZone

signal before_cards_played(board, slotIndex, cardsFusing)
signal after_cards_played(board, slotIndex, cardsFusing)

func onCardsPlayed(board, slotIndex, cardsFusing):
	before_cards_played.emit(board, slotIndex, cardsFusing)
	eraseCards(cardsFusing)
	board.onCardsPlayed(slotIndex, cardsFusing)
	after_cards_played.emit(board, slotIndex, cardsFusing)
