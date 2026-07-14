extends AnimatedButton

@onready var transition: Node2D = %Transition
@onready var toast: Control = %Toast

@onready var exit_text: Label = $Text
@onready var exit_hold_text: Label = $HoldText
@onready var exit_hold_progress: Panel = $HoldText/HoldProgress

const REQUIRED_HOLD_TIME = 3
var hold_transparency_tween
var exit_start_hold_time = -1
var is_holding_delete_button = false

## Mode 0: default; mode 1: delete timer
func set_mode(mode: int):
	if hold_transparency_tween and hold_transparency_tween.is_running():
		hold_transparency_tween.kill()
	
	
	hold_transparency_tween = create_tween()
	hold_transparency_tween.set_parallel()
	hold_transparency_tween.tween_property(
		exit_text, "modulate", Color(1, 1, 1, 1 - mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	hold_transparency_tween.tween_property(
		exit_hold_text, "modulate", Color(1, 1, 1, mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	hold_transparency_tween.play()

var delete_tick := 0

func _on_button_down() -> void:
	delete_tick += 1
	delete_tick %= 10000
	var this_delete_tick = delete_tick
	
	
	exit_start_hold_time = Time.get_ticks_msec()
	is_holding_delete_button = true
	
	set_mode(1)
	
	await get_tree().create_timer(REQUIRED_HOLD_TIME).timeout
	if not is_holding_delete_button or delete_tick != this_delete_tick: return
	
	set_mode(0)
	transition.transition(modulate, "Title", get_global_mouse_position())


func _on_button_up() -> void:
	# Will get set to false if the delete is followed throught with
	if is_holding_delete_button:
		set_mode(0)
		is_holding_delete_button = false
		var time_elapsed = float(Time.get_ticks_msec() - exit_start_hold_time) / 1000.0
		if time_elapsed < 0.2:
			toast.toast("Hold to exit!", 2.5, {
				"modulate": Color(1.0, 0.6, 0.3)
			})


func _process(_delta: float):
	if not is_holding_delete_button: return
	 
	@warning_ignore("integer_division")
	var time_elapsed = float(Time.get_ticks_msec() - exit_start_hold_time) / 1000.0
	exit_hold_text.text = "[%.1f]" % time_elapsed
	
	exit_hold_progress.anchor_right = time_elapsed / REQUIRED_HOLD_TIME
