extends Node2D

@onready var title: Node2D = %Title
@onready var game: Node2D = %Game

var active = "Title"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	title.visible = true
	game.visible = false
