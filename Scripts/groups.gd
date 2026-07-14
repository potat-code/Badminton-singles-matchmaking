extends Control

@onready var toast: Control = %Toast
@onready var transition: Node2D = %Transition
@onready var tab_bar: TabBar = $"../TabBar"
@onready var players: Control = $"../Players"

@export var group_template: PackedScene
@onready var options: VBoxContainer = $Options

@onready var groups: VBoxContainer = $Scroll/Control/Main
@onready var new_group: AnimatedButton = $Options/NewGroup
@onready var new_group_text: Label = $Options/NewGroup/Text
@onready var new_group_line_edit: LineEdit = $Options/NewGroup/LineEdit
@onready var new_group_cancel: AnimatedButton = $Options/NewGroup/LineEdit/Cancel
@onready var new_group_confirm: AnimatedButton = $Options/NewGroup/LineEdit/Confirm
@onready var new_group_character_limit: Label = $Options/NewGroup/LineEdit/CharacterLimit

@onready var load_group: AnimatedButton = $Options/LoadGroup

@onready var edit_group: AnimatedButton = $Options/EditGroup
@onready var edit_group_text: Label = $Options/EditGroup/Text

@onready var edit_group_main: Control = $Options/EditGroup/Main
@onready var edit_group_main_cancel: AnimatedButton = $Options/EditGroup/Main/Cancel
@onready var edit_group_edit_name: AnimatedButton = $Options/EditGroup/Main/EditName
@onready var edit_group_edit_players: AnimatedButton = $Options/EditGroup/Main/EditPlayers

@onready var edit_group_name: Control = $Options/EditGroup/Name
@onready var edit_group_name_line_edit: LineEdit = $Options/EditGroup/Name/LineEdit
@onready var edit_group_name_cancel: AnimatedButton = $Options/EditGroup/Name/LineEdit/Cancel
@onready var edit_group_name_confirm: AnimatedButton = $Options/EditGroup/Name/LineEdit/Confirm

@onready var edit_group_players: Control = $Options/EditGroup/Players
@onready var edit_group_add_to_group: AnimatedButton = $"../AddToGroup"
@onready var edit_group_add_to_group_text: Label = $"../AddToGroup/Text"
@onready var edit_group_remove_from_group: AnimatedButton = $"../RemoveFromGroup"

@onready var delete_group: AnimatedButton = $Options/DeleteGroup
@onready var delete_group_text: Label = $Options/DeleteGroup/Text
@onready var delete_group_hold_text: Label = $Options/DeleteGroup/HoldText
@onready var delete_group_hold_progress: Panel = $Options/DeleteGroup/HoldText/HoldProgress


var group_data = null
var selected_group: GroupBanner = null

var groups_path = "user://Save/Groups"

var new_group_mode = -1
var is_editting = false
var is_editting_players = false


func set_selected_group(group: GroupBanner):
	if group:
		group.set_selected()
	else:
		selected_group.set_selected(false)
	selected_group = group
	
	var bool_value = group == null
	
	load_group.disabled = bool_value
	edit_group.disabled = bool_value
	delete_group.disabled = bool_value
	


func on_group_clicked(group: GroupBanner):
	#print("Group [", group.group_name, "] (", group, ") clicked")
	if group != selected_group:
		set_selected_group(group)
	else:
		if not is_editting:
			set_selected_group(null)
		else:
			toast.toast("Stop editing to deselect!", 3,
				{"modulate" = Color(1.0, 0.3, 0.3, 1.0)})

## Mode 0: default; mode 1: text edit
func set_new_group_mode(mode: int):
	if mode == new_group_mode: return
	new_group_mode = mode
	
	new_group_line_edit.editable = mode == 1
	var new_mouse_filter = Control.MOUSE_FILTER_IGNORE if mode == 0 else Control.MOUSE_FILTER_STOP
	new_group_line_edit.mouse_filter = new_mouse_filter
	
	new_group_cancel.disabled = mode == 0
	new_group_cancel.mouse_filter = new_mouse_filter
	new_group_confirm.disabled = mode == 0
	new_group_confirm.mouse_filter = new_mouse_filter
	
	if mode == 1:
		new_group_line_edit.text = ""
		on_line_edit_text_changed(new_group_line_edit.text, new_group_line_edit)
	
	
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(
		new_group, "self_modulate", Color(1, 1, 1, 1 - mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		new_group_text, "self_modulate", Color(1, 1, 1, 1 - mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		new_group_line_edit, "modulate", Color(1, 1, 1, mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.play()

func get_descendants(node: Node):
	var nodes : Array = []

	for N in node.get_children():
		if N.get_child_count() > 0:
			nodes.append(N)
			nodes.append_array(get_descendants(N))
		else:
			nodes.append(N)

	return nodes

## Pass the control that should be enabled
func set_edit_group_mode(mode: int, control: Control):
	is_editting = mode == 1 and control
	
	var tween = create_tween()
	tween.set_parallel()
	tween.tween_property(
		edit_group, "self_modulate", Color(1, 1, 1, 0 if control else 1), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		edit_group_text, "self_modulate", Color(1, 1, 1, 0 if control else 1), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	
	edit_group.mouse_filter = Control.MOUSE_FILTER_IGNORE if mode == 1 else Control.MOUSE_FILTER_STOP
	
	for other_control in edit_group.get_children():
		if other_control.is_class("Label") or other_control.is_class("ColorRect"): continue
		
		tween.tween_property(
			other_control, "modulate", Color(1, 1, 1, mode if other_control == control else 0), 0.5
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		var is_ignore = mode == 0 or other_control != control
		var new_mouse_filter = Control.MOUSE_FILTER_IGNORE if is_ignore else Control.MOUSE_FILTER_STOP
		
		other_control.mouse_filter = new_mouse_filter
		for node: Control in get_descendants(other_control):
			if node.is_class("Label") or node.is_class("ColorRect"):
				node.mouse_filter = Control.MOUSE_FILTER_IGNORE
			else:
				node.mouse_filter = new_mouse_filter
	
	if mode == 1:
		edit_group_name_line_edit.text = ""
		on_line_edit_text_changed(edit_group_name_line_edit.text, edit_group_name_line_edit)
	
	tween.play()


func set_edit_players_mode(mode: int):
	var tween = create_tween()
	tween.set_parallel()
	
	if mode:
		edit_group_add_to_group_text.text = "Add to group: " + selected_group.group_name
		players.configure_group_editting_buttons()
	tween.tween_property(
		edit_group_add_to_group, "modulate", edit_group.modulate * Color(1, 1, 1, mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		edit_group_remove_from_group, "modulate", edit_group.modulate * Color(1, 1, 1, mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.play()

func create_group_banner(group_name: String):
	var group = group_template.instantiate()
	group.modulate = GROUP_TRANSPARENT_MODULATE
	
	groups.add_child(group)
	group.pressed.connect(on_group_clicked.bind(group))
	group.set_group_name(group_name)
	var tween = create_tween()
	tween.tween_property(
		group, "modulate", GROUP_DEFAULT_MODULATE, 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.play()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_new_group_mode(0)
	set_edit_group_mode(0, null)
	set_edit_players_mode(0)
	load_group.disabled = true
	edit_group.disabled = true
	delete_group.disabled = true
	
	if not DirAccess.dir_exists_absolute(groups_path):
		DirAccess.make_dir_recursive_absolute(groups_path)
	if not FileAccess.file_exists("user://Save/README.md"):
		var file = FileAccess.open("user://Save/REDME.md", FileAccess.WRITE)
		file.store_string("""
# Hey!
DO NOT try to edit the data of any files...
If you _must_, follow these guidelines:
    1. You may edit the name of and delete groups, however do not edit the data
    2. Do not rename or change the data any players
        2b. If you do rename a player, they will be typically be removed from any groups they are in, as the app
		will not know what player you renamed. The exception is when you rename a file to overwrite another;
		in this case, the file will be overwriten as expected.
		2c. You may safely delete players
	3. You may delete the "Groups" or master "Save" directory to purge it

but probably dont touch anything at all, that's you best bet ;_;

also all those cartoon character are from a web series called Battle For Dream Island.
People say its bad because theyve only watched the worst of it (season 4b and season 1)
but seriously its better than most movies/tv shows
u gotta watch it
im gripping my boots for TPOT 24
""")
	
	if not players.is_loaded:
		await players.loaded
	
	var temp_group_data = {}
	for group_name in DirAccess.get_files_at(groups_path):
		var file_path = groups_path + "/" + group_name
		var without_extention = group_name.substr(0, len(group_name) - 6)
		var file = FileAccess.open(file_path, FileAccess.READ_WRITE)
		var data = file.get_var()
		if typeof(data) != TYPE_ARRAY:
			data = []
			file.store_var([])
			toast.toast("The group: %s was corrupted!", 5, {"modulate" = Color(1, 0.4, 0.4)})
		
		for player_name in data.duplicate():
			if not player_name in players.player_data.keys():
				data.erase(player_name)
		temp_group_data[without_extention] = data
				
		create_group_banner(without_extention)
	
	new_group.pressed.connect(set_new_group_mode.bind(1))
	new_group_cancel.pressed.connect(set_new_group_mode.bind(0))
	new_group_line_edit.text_changed.connect(on_line_edit_text_changed.bind(new_group_line_edit))
	
	edit_group.pressed.connect(set_edit_group_mode.bind(1, edit_group_main))
	
	edit_group_edit_name.pressed.connect(set_edit_group_mode.bind(1, edit_group_name))
	edit_group_edit_players.pressed.connect(func():
		set_edit_group_mode(1, edit_group_players)
		set_edit_players_mode(1)
		tab_bar.current_tab = 1
		is_editting_players = true
	)
	edit_group_main_cancel.pressed.connect(set_edit_group_mode.bind(0, null))
	
	edit_group_name_line_edit.text_changed.connect(on_line_edit_text_changed.bind(edit_group_name_line_edit))
	edit_group_name_cancel.pressed.connect(set_edit_group_mode.bind(0, null))
	
	
	group_data = temp_group_data


func on_line_edit_text_changed(text: String, line_edit: LineEdit) -> void:
	line_edit.get_node("CharacterLimit").text = str(len(text)) + "/20"

const GROUP_DEFAULT_MODULATE = Color(1, 0.694, 0.051, 1)
const GROUP_TRANSPARENT_MODULATE = Color(1, 0.694, 0.051, 0)

func _on_confirm_pressed(is_edit: bool = false) -> void:
	var new_name = new_group_line_edit.text if not is_edit else edit_group_name_line_edit.text
	var current_selected_group = selected_group
	
	if new_name in group_data:
		toast.toast("Name already used!", 2, {"modulate" = Color(1.0, 0.3, 0.3, 1.0)})
		return
	if not new_name.is_valid_filename():
		toast.toast("Do not use the following characters:\n" + r' : / \ ? * " | % < >', 3,
			{"modulate" = Color(1.0, 0.3, 0.3, 1.0)})
		return
	
	if is_edit:
		set_edit_group_mode(0, null)
		var old_group_name = current_selected_group.group_name
		DirAccess.remove_absolute(groups_path + "/" + old_group_name + ".group")
		group_data.erase(old_group_name)
		current_selected_group.set_group_name(new_name)
	else:
		create_group_banner(new_name)
		set_new_group_mode(0)
	
	var file = FileAccess.open(groups_path + "/" + new_name  + ".group", FileAccess.WRITE)
	file.store_var([])
	group_data[new_name] = []

var is_holding_delete_button = false
var delete_group_start_hold_time := -1
const REQUIRED_HOLD_TIME := 5.0

var hold_transparency_tween: Tween

## Mode 0: default; mode 1: delete timer
func set_delete_button_mode(mode: int):
	if hold_transparency_tween and hold_transparency_tween.is_running():
		hold_transparency_tween.kill()
	
	
	hold_transparency_tween = create_tween()
	hold_transparency_tween.set_parallel()
	hold_transparency_tween.tween_property(
		delete_group_text, "modulate", Color(1, 1, 1, 1 - mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	hold_transparency_tween.tween_property(
		delete_group_hold_text, "modulate", Color(1, 1, 1, mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	hold_transparency_tween.play()

var delete_tick := 0

func _on_delete_group_button_down() -> void:
	if not selected_group: return
	
	delete_tick += 1
	delete_tick %= 10000
	var this_delete_tick = delete_tick
	
	
	delete_group_start_hold_time = Time.get_ticks_msec()
	is_holding_delete_button = true
	
	set_delete_button_mode(1)
	
	await get_tree().create_timer(REQUIRED_HOLD_TIME).timeout
	if not is_holding_delete_button or delete_tick != this_delete_tick: return
	
	# <--- GROUP HAS BEEN DELETED ---> #
	
	var group_deleting = selected_group # Avoid race conditions
	
	DirAccess.remove_absolute(groups_path + "/" + group_deleting.group_name + ".group")
	group_data.erase(group_deleting.group_name)
	
	set_selected_group(null)
	set_delete_button_mode(0)
	
	var tween = create_tween()
	tween.tween_property(
		group_deleting, "modulate", GROUP_TRANSPARENT_MODULATE, 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	var order = group_deleting.get_index()
	
	await tween.finished
	
	group_deleting.queue_free()
	
	var space = Control.new()
	space.offset_bottom = 0
	space.custom_minimum_size = Vector2(0, 120)
	groups.add_child(space)
	groups.move_child(space, order)
	
	tween = create_tween()
	tween.tween_property(
		space, "custom_minimum_size", Vector2(0, 0), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	
	tween.play()
	
	await tween.finished
	
	space.queue_free()
	


func _on_delete_group_button_up() -> void:
	if not selected_group: return
	# Will get set to false if the delete is followed throught with
	if is_holding_delete_button:
		set_delete_button_mode(0)
		is_holding_delete_button = false


func _on_load_group_pressed() -> void:
	transition.transition(load_group.modulate, "Game", get_global_mouse_position(), selected_group.group_name)
	
	await get_tree().create_timer(2).timeout
	
	if selected_group:
		set_selected_group(null)


func _on_add_to_group_pressed() -> void:
	if not selected_group: return
	
	var current_selected_group = selected_group
	
	var data = group_data[current_selected_group.group_name]
	
	for player in players.selected_players.duplicate():
		if not player.file_name in data:
			data.append(player.file_name)
	
	players.configure_group_editting_buttons()
	
	var file = FileAccess.open(groups_path + "/" + current_selected_group.group_name + ".group", FileAccess.WRITE)
	file.store_var(data)


func _on_remove_from_group_pressed() -> void:
	if not selected_group: return
	
	var current_selected_group = selected_group
	
	var data = group_data[current_selected_group.group_name]
	
	for player in players.selected_players.duplicate():
		if player.file_name in data:
			data.erase(player.file_name)
	
	players.configure_group_editting_buttons()
	
	var file = FileAccess.open(groups_path + "/" + current_selected_group.group_name + ".group", FileAccess.WRITE)
	file.store_var(data)


func _on_edit_players_confirm_pressed() -> void:
	set_edit_group_mode(0, null)
	set_edit_players_mode(0)


func _process(_delta: float):
	if not is_holding_delete_button: return
	 
	@warning_ignore("integer_division")
	var time_elapsed = float(Time.get_ticks_msec() - delete_group_start_hold_time) / 1000.0
	delete_group_hold_text.text = "[%.1f]" % time_elapsed
	
	delete_group_hold_progress.anchor_right = time_elapsed / REQUIRED_HOLD_TIME
	
	edit_group_add_to_group.disabled = tab_bar.current_tab == 0 or players.selected_players.size() == 0
