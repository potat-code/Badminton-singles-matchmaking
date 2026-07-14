extends Control

@onready var groups: Control = $Groups
@onready var players: Control = $Players



var tab_change_tween: Tween = null

func _on_tab_changed(tab: int) -> void:
	if tab_change_tween and tab_change_tween.is_running():
		tab_change_tween.kill()
	tab_change_tween = create_tween()
	tab_change_tween.set_parallel()
	tab_change_tween.tween_property(
		groups, "position", Vector2(-tab * 1000.0, 34.0), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tab_change_tween.tween_property(
		players, "position", Vector2(1000.0 - tab * 1000.0, 34.0), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tab_change_tween.play()

func _ready():
	_on_tab_changed(0)
