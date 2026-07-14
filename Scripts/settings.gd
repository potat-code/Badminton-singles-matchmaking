extends Control

@onready var main: VBoxContainer = $Main

var settings: Dictionary

func _ready():
	var file = FileAccess.open("user://Save/settings.json", FileAccess.READ_WRITE)
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	custom_minimum_size.y = main.size.y
