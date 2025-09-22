extends AudioManager

const SIGMA_BASE : float = 0.05

const soundCardHit : AudioStream = preload("res://Audio/Sounds/card_hit.ogg")

const soundCardPlaced0  : AudioStream = preload("res://Audio/Sounds/card_placed0.ogg")
const soundCardPlaced1  : AudioStream = preload("res://Audio/Sounds/card_placed1.ogg")
const soundCardPlaced2  : AudioStream = preload("res://Audio/Sounds/card_placed2.ogg")
const soundCardPlaced3  : AudioStream = preload("res://Audio/Sounds/card_placed3.ogg")
const soundCardPlaced4  : AudioStream = preload("res://Audio/Sounds/card_placed4.ogg")
const soundCardPlaced5  : AudioStream = preload("res://Audio/Sounds/card_placed5.ogg")
const soundCardPlaced6  : AudioStream = preload("res://Audio/Sounds/card_placed6.ogg")
const soundCardPlaced7  : AudioStream = preload("res://Audio/Sounds/card_placed7.ogg")
const soundCardPlaced8  : AudioStream = preload("res://Audio/Sounds/card_placed8.ogg")
const soundCardPlaced9  : AudioStream = preload("res://Audio/Sounds/card_placed9.ogg")
const soundCardPlaced10 : AudioStream = preload("res://Audio/Sounds/card_placed10.ogg")
const soundCardPlaced11 : AudioStream = preload("res://Audio/Sounds/card_placed11.ogg")
const soundListCardPlaced : Array = [
	soundCardPlaced0, soundCardPlaced1, soundCardPlaced2, soundCardPlaced3, soundCardPlaced4, soundCardPlaced5, 
	soundCardPlaced6, soundCardPlaced7, soundCardPlaced8, soundCardPlaced9, soundCardPlaced10, soundCardPlaced11
]

const soundCardSelect : AudioStream = preload("res://Audio/Sounds/card_select.ogg")

const soundCardTear : AudioStream = preload("res://Audio/Sounds/card_tear.mp3")

func playCardHit() -> void:
	createAudioStreamPlayer(soundCardHit, 1.0, SIGMA_BASE)

func playCardPlaced() -> void:
	var stream : AudioStream = soundListCardPlaced[randi() % soundListCardPlaced.size()]
	createAudioStreamPlayer(stream)

func playCardSelect() -> void:
	createAudioStreamPlayer(soundCardSelect, 1.0, SIGMA_BASE)

func playCardTear() -> void:
	createAudioStreamPlayer(soundCardTear, 1.0, SIGMA_BASE)
