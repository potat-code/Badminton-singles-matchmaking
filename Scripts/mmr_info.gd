extends AnimatedButton

@onready var toast: Control = %Toast

func _on_pressed() -> void:
	toast.toast("1000 MMR: Beginner\n2500 MMR: Intermediate\n5000 MMR: Advanced", 5)
