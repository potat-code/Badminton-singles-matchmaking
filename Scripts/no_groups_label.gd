extends Label

@export var id: String

@onready var main: VBoxContainer = $"../Main"
var tween = null

var is_shown = true

var group_count = 0

## Dynamically changes if the label is shown.
func change_shown():
	if is_shown != (group_count == 0):
		is_shown = group_count == 0
		if tween and tween.is_running():
			tween.kill()
		
		tween = create_tween()
		
		tween.tween_property(
			self, "modulate", Color(1, 1, 1, 1 if is_shown else 0), 0.5
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		tween.play()


func _on_child_entered_tree(node: Node, connecter_id: String) -> void:
	if connecter_id != id: return
	
	if node.is_class("Button") or node.is_class("HBoxContainer"):
		group_count += 1
		change_shown()


func _on_child_exiting_tree(node: Node, connecter_id: String) -> void:
	if connecter_id != id: return
	
	if node.is_class("Button") or node.is_class("HBoxContainer"):
		group_count -= 1
		change_shown()
