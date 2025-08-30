extends Node

const deckEditorPath : String = "res://Scenes/DeckEditor.tscn"
const mainMenuPath : String = "res://Scenes/MainMenu.tscn"
const mainPath : String = "res://Scenes/Main.tscn"
const multiplayerPath : String = "res://Scenes/MultiplayerLobby.tscn"

const cardBackground = preload("res://Art/backgrounds/card_blank.png")
const cardBackgroundActive = preload("res://Art/backgrounds/card_active.png")
const unknownCardTex = preload("res://Art/portraits/card_unknown.png")
const cardbackDefault = preload("res://Art/cardbacks/default.png")
const noneCardTex = preload("res://Art/portraits/card_NONE.png")

const cardNodePacked : PackedScene = preload("res://Scenes/CardNode.tscn")
