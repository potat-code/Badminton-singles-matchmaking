class_name AnimatedButton extends Button

@onready var select_bar = preload("res://Scenes/select_bar.tscn").instantiate()
var mouse_enter_tween: Tween = null

func on_mouse_entered():
	if disabled: return
	if mouse_enter_tween and mouse_enter_tween.is_running():
		mouse_enter_tween.kill()
	mouse_enter_tween = create_tween()
	mouse_enter_tween.set_parallel()
	var offset_left_tween = mouse_enter_tween.tween_property(select_bar, "offset_left", -size.x / 2, 0.5)
	offset_left_tween.set_trans(Tween.TRANS_QUART)
	offset_left_tween.set_ease(Tween.EASE_OUT)
	var offset_right_tween = mouse_enter_tween.tween_property(select_bar, "offset_right", size.x / 2, 0.5)
	offset_right_tween.set_trans(Tween.TRANS_QUART)
	offset_right_tween.set_ease(Tween.EASE_OUT)
	mouse_enter_tween.play()
	
func on_mouse_leave():
	if mouse_enter_tween and mouse_enter_tween.is_running():
		mouse_enter_tween.kill()
	mouse_enter_tween = create_tween()
	mouse_enter_tween.set_parallel()
	var offset_left_tween = mouse_enter_tween.tween_property(select_bar, "offset_left", 0, 0.25)
	offset_left_tween.set_trans(Tween.TRANS_QUART)
	offset_left_tween.set_ease(Tween.EASE_OUT)
	var offset_right_tween = mouse_enter_tween.tween_property(select_bar, "offset_right", 0, 0.25)
	offset_right_tween.set_trans(Tween.TRANS_QUART)
	offset_right_tween.set_ease(Tween.EASE_OUT)
	mouse_enter_tween.play()

func _ready():
	add_child(select_bar)
	select_bar.offset_left = 0
	select_bar.offset_right = 0
	mouse_entered.connect(on_mouse_entered)
	mouse_exited.connect(on_mouse_leave)
