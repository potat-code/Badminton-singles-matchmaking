extends Node2D

@onready var title: Node2D = %Title
@onready var game: Node2D = %Game

var active = "Title"
var is_fullscreen = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	title.visible = true
	game.visible = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Fullscreen"):
		is_fullscreen = !is_fullscreen
		if is_fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
