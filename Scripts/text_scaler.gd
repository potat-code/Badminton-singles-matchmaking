extends Control

@onready var player_one: LineEdit = $PlayerOne
@onready var player_two: LineEdit = $PlayerTwo

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	player_one.add_theme_font_size_override("font_size", 20 + 36 if player_one.text else 0)
	player_two.add_theme_font_size_override("font_size", 20 + 36 if player_two.text else 0)
