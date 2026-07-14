extends Control

@export var toast_label: PackedScene


func destroy_toast(label: Label, has_manually_dismissed: bool = false):
	if label.is_destroying: return
	label.is_destroying = true
	
	if label.tween and label.tween.is_running():
		label.tween.kill()
	
	var disable_tween = create_tween()
	disable_tween.set_parallel()
	if has_manually_dismissed:
		disable_tween.tween_property(
			label.get_node("Time"), "anchor_right", 1.0, 0.5
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	disable_tween.tween_property(
		label, "position", Vector2(1152, label.position.y), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN).set_delay(
		0.2 if has_manually_dismissed else 0.0
	)
	disable_tween.play()
	
	await disable_tween.finished
	
	var valid_toasts = []
	for other_toast in get_children():
		if other_toast == label: break
		if other_toast.is_destroying: continue
		valid_toasts.append(other_toast)
	
	if len(valid_toasts) > 0:
		var tween = create_tween()
		tween.set_parallel()
		var i = 0.0
		for other_toast in valid_toasts:
			tween.tween_property(
				other_toast, "position", Vector2(576, other_toast.position.y + label.size.y + 5), 0.5
			).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT).set_delay(i / 25)
			i += 1
			other_toast.target_y += label.size.y + 5
		tween.play()
	
	label.queue_free()

func toast(text: String = "", time: float = 3.0, properties: Dictionary = {}):
	var label: Label = toast_label.instantiate()
	label.text = text
	for key in properties.keys():
		label[key] = properties[key]
	
	
	var valid_toasts_count = 0
	for other_toast in get_children():
		if other_toast.is_destroying: continue
		valid_toasts_count += 1
	
	var iterable = get_children()
	iterable.reverse()
	
	add_child(label)
	var label_size_y = label.get_minimum_size().y
	label.size.y = label_size_y
	var this_y_position = DisplayServer.window_get_size().y - label.size.y - 10
	label.position = Vector2(576 + 1152, this_y_position)
	label.target_y = this_y_position
	
	if valid_toasts_count > 0:
		var other_tween = create_tween()
		other_tween.set_parallel()
		var i = 0.0
		for other_label in iterable:
			if other_label.is_destroying: continue
			if other_label == label: continue
			other_label.target_y -= label_size_y + 5
			other_tween.tween_property(
				other_label, "position", Vector2(576, other_label.target_y), 0.5
			).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT).set_delay(i / 25)
			i += 1
		other_tween.play()
	
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(
		label, "position", Vector2(576, this_y_position), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		label.get_node("Time"), "anchor_right", 1.0, time
	).set_trans(Tween.TRANS_LINEAR)
	tween.play()
	
	label.tween = tween
	label.get_node("Dismiss").pressed.connect(destroy_toast.bind(label, true))
	tween.finished.connect(destroy_toast.bind(label))

func _ready():
	var chars = "qwertyuiopasdfghjklzxcvbnmQWERTYUPASDFGHJKLZXCVBNM1234567890!$&%"
	var debug_token = ""
	for i in range(16):
		debug_token += chars[randi_range(0, 63)]
	
	await get_tree().create_timer(1).timeout
	toast("Debug token created: " + debug_token, 6)
