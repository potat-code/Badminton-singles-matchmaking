extends AnimatedButton

@export var back_option_template: PackedScene
@onready var back_picker: ScrollContainer = $"../../BackPicker"
@onready var vbox_container: VBoxContainer = $"../../BackPicker/VBoxContainer"
@onready var color_rect: ColorRect = $ColorRect
@onready var texture_rect: TextureRect = $ColorRect/TextureRect

var enabled = false
var selected_image = ""


func on_option_pressed(file_name):
	selected_image = file_name
	set_enabled(false)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerBacks.init()
	
	var disable_option = back_option_template.instantiate()
	disable_option.get_node("Image").modulate = Color.TRANSPARENT
	disable_option.get_node("Text").text = "Disable"
	disable_option.pressed.connect(on_option_pressed.bind(""))
	vbox_container.add_child(disable_option)
	
	for file_name in PlayerBacks.backs:
		var back_option = back_option_template.instantiate()
		back_option.get_node("Image").texture = PlayerBacks.backs[file_name]
		var color = PlayerBacks.colors[file_name] if file_name in PlayerBacks.colors else Color.BLACK
		back_option.get_node("Image/ColorRect").color = color
		
		vbox_container.add_child(back_option)
		
		back_option.pressed.connect(on_option_pressed.bind(file_name))
	
	set_enabled(false)


func set_enabled(on: bool):
	enabled = on
	var new_mouse_filter = Control.MOUSE_FILTER_STOP if on else Control.MOUSE_FILTER_IGNORE
	back_picker.mouse_filter = new_mouse_filter
	vbox_container.mouse_filter = new_mouse_filter
	for option in vbox_container.get_children():
		option.mouse_filter = new_mouse_filter
	
	var tween = create_tween()
	tween.tween_property(
		back_picker,
		"modulate",
		Color(1, 1, 1, 1 if enabled else 0),
		0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.play()


func _on_pressed() -> void:
	set_enabled(not enabled)


func _process(_delta):
	if selected_image != "":
		color_rect.modulate = Color.WHITE
		color_rect.color = PlayerBacks.colors[selected_image]
		texture_rect.texture = PlayerBacks.backs[selected_image]
	else:
		color_rect.modulate = Color.TRANSPARENT
