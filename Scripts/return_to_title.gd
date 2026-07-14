extends AnimatedButton

@onready var transition: Node2D = %Transition

func _on_pressed() -> void:
	transition.transition(modulate, "Title", get_global_mouse_position())
