## Decrases the RichTextLabel's `scale` if it doesnt fit the container.
class_name ContentFitter extends Control

@onready var child: Control = get_children()[0]

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not child: return
	var width = size.x * scale.x
	var child_width = child.get_minimum_size().x
	child.scale = Vector2.ONE * min(width / child_width, 1)
	
	var height = size.y * scale.y
	var child_height = child.get_minimum_size().y
	child.scale = Vector2.ONE * min(height / child_height, child.scale.x)
