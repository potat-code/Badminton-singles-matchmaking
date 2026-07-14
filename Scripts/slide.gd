extends Node2D

@export var slide_image: PackedScene
var slides = []

const SLIDE_IMAGES = 5


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(SLIDE_IMAGES):
		var new_slide_image = slide_image.instantiate()
		new_slide_image.modulate = Color.from_ok_hsl(0.6 + i * 0.05, 0.8, 0.5)
		new_slide_image.position = Vector2(1600, 0)
		add_child(new_slide_image)
		slides.append(new_slide_image)
	
	while true:
		for s in range(-1, 3, 2):
			for m in range(2):
				for slide in slides:
					var tween = create_tween()
					var tween_property = tween.tween_property(slide, "position", Vector2(m * s * 1600, 0), 1)
					tween_property.set_trans(Tween.TRANS_QUART)
					tween_property.set_ease(Tween.EASE_IN)
					tween.play()
					await get_tree().create_timer(0.1).timeout
					
				await get_tree().create_timer(1).timeout
				slides.reverse()
				
			await get_tree().create_timer(0.5).timeout
