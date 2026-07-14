extends Node2D

@export var slide: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(5):
		var new_slide = slide.instantiate()
		new_slide.position = Vector2(0, -450 + i * 180)
		add_child(new_slide)
		await get_tree().create_timer(0.06).timeout
