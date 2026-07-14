extends AnimatedButton


func _on_pressed() -> void:
	var tween = create_tween()
	tween.tween_property(
		get_node("/root/Main"), "modulate", Color(1, 1, 1, 0), 1
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.play()
	await tween.finished
	get_tree().quit()
