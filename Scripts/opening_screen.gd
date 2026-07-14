extends Node2D

@onready var bar: Sprite2D = $Bar

var texts = [
	
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(10):
		var new_bar = bar.duplicate()
		new_bar.position += Vector2(0, i * 65)
		add_child(new_bar)
		
	visible = true
	
	await get_tree().create_timer(0.5).timeout
	
	var tween = create_tween()
	tween.set_parallel()
	var i = 0
	@warning_ignore("shadowed_variable")
	for bar in get_children():
		if bar.name == "Title": continue
		var tween_property = tween.tween_property(bar, "position", bar.position - Vector2(1152, 0), 0.5)
		tween_property.set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
		tween_property.set_delay(float(i) / 20)
		i += 1
	tween.play()
	
	await tween.finished
	
	queue_free()
