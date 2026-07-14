extends Node2D

@export var circle_template: PackedScene
@export var slide_template: PackedScene
@onready var game_main: Control = $"../Game/Main"
@onready var main: Node2D = $".."

@onready var scenes = {
	"Title": %Title,
	"Game": %Game
}

func transition(modulation: Color, new_scene: String, create_position: Vector2, group_enabling: String = ""):
	var circles = []
	var tween = create_tween()
	tween.set_parallel()
	
	var iterations = 5
	for i in range(iterations):
		var circle = circle_template.instantiate()
		circles.append(circle)
		#circle.modulate = Color(modulation.r, modulation.g, modulation.b, 0.5 if i != 4 else 1.0)
		circle.modulate = modulation * Color(1, 1, 1, float(i + 1) / iterations)
		circle.size = Vector2.ZERO
		circle.position = create_position
		
		add_child(circle)
		
		var new_size = 3000 #* (float(i + 1) / iterations)
		var delay_offset = 0 #0.5 if i > 0 else 0.0
		
		tween.tween_property(
			circle, "size", Vector2.ONE * new_size, 1
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN).set_delay(float(i) / 5 + delay_offset)
		tween.tween_property(
			circle, "position", create_position + -Vector2.ONE * new_size / 2, 1
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN).set_delay(float(i) / 5 + delay_offset)
		tween.tween_property(
			circle, "rotation", i * 20, 2
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN).set_delay(float(i) / 5 + delay_offset)
		
	tween.play()
	
	await tween.finished
	main.active = new_scene
	for scene_key in scenes:
		scenes[scene_key].visible = false
	scenes[new_scene].visible = true
	if new_scene == "Game":
		game_main.init(group_enabling)
	
	await get_tree().create_timer(0.5).timeout
	
	tween = create_tween()
	tween.set_parallel()
	
	var slides =  []
	for s in range(2):
		var slide = slide_template.instantiate()
		slides.append(slide)
		slide.modulate = modulation
		slide.size = Vector2(576, 648)
		slide.position = Vector2((-1 + s) * 576, -324)
		
		add_child(slide)
		
		tween.tween_property(
			slide, "position", Vector2((-2 + s * 3) * 576, -324), 2
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	for circle in circles:
		circle.queue_free()
	
	tween.play()
	
	await tween.finished
	
	for slide in slides:
		slide.queue_free()
