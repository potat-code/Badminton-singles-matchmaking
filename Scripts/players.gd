extends Control

@onready var toast: Control = %Toast
@onready var transition: Node2D = %Transition
@onready var groups: Control = $"../Groups"
@onready var title: Node2D = %Title

@export var player_template: PackedScene
@onready var options: VBoxContainer = $Options

@onready var players: VBoxContainer = $Scroll/Control/Main
@onready var add_player_to_group: AnimatedButton = $"../AddToGroup"
@onready var remove_player_from_group: AnimatedButton = $"../RemoveFromGroup"

@onready var new_player: AnimatedButton = $Options/NewPlayer
@onready var new_player_text: Label = $Options/NewPlayer/Text

@onready var create_cancel: AnimatedButton = $Create/Cancel
@onready var create_confirm: AnimatedButton = $Create/Confirm

@onready var create: Control = $Create
@onready var create_first_name: LineEdit = $Create/FirstName
@onready var create_last_name: LineEdit = $Create/LastName
@onready var create_date_of_birth: LineEdit = $Create/DateOfBirth
@onready var create_mmr: LineEdit = $Create/MMR
@onready var line_edits: Array[LineEdit] = [
	create_first_name,
	create_last_name,
	create_date_of_birth,
	create_mmr,
]
@onready var create_back_picker: Button = $Create/BackPicker

@onready var edit_player: AnimatedButton = $Options/EditPlayer
@onready var edit_player_modulate = edit_player.modulate

@onready var delete_player: AnimatedButton = $Options/DeletePlayer
@onready var delete_player_text: Label = $Options/DeletePlayer/Text
@onready var delete_player_hold_text: Label = $Options/DeletePlayer/HoldText
@onready var delete_player_hold_progress: Panel = $Options/DeletePlayer/HoldText/HoldProgress

## "create" or "edit"
var create_type = null
var player_data: Dictionary
var selected_players: Array[PlayerBanner] = []

var players_path = "user://Save/Players"

var create_mode = -1

## Used to signify when groups can start loading data because all player data has loaded.
signal loaded
var is_loaded = false

## Changes if the add_to_group and remove_from_group buttons are enabled.
func configure_group_editting_buttons():
	if selected_players.size() == 0:
		add_player_to_group.disabled = true
		remove_player_from_group.disabled = true
		
		return
	
	# Status 0: None in group; Status 1: Mixed; Status 2: All in group
	var group_status = -1
	var this_group_data = groups.group_data[groups.selected_group.group_name]
	for selected_player in selected_players:
		var is_player_in_group = selected_player.file_name in this_group_data
		if group_status == -1:
			group_status = 2 if is_player_in_group else 0
		elif group_status == 0 and is_player_in_group:
			group_status = 1
			break
		elif group_status == 2 and not is_player_in_group:
			group_status = 1
			break
	
	if group_status == 1 or group_status == -1:
		add_player_to_group.disabled = false
		remove_player_from_group.disabled = false
	elif group_status == 0:
		add_player_to_group.disabled = false
		remove_player_from_group.disabled = true
	elif group_status == 2:
		add_player_to_group.disabled = true
		remove_player_from_group.disabled = false


## `deselect` is the player that should be deselected when you click on already selected player
func set_selected_player(player: PlayerBanner, deselect: PlayerBanner = null):
	if player:
		player.set_selected(true)
		if not Input.is_action_pressed("Shift"):
			for other_player in selected_players.duplicate():
				other_player.set_selected(false)
				selected_players.erase(other_player)
		selected_players.append(player)
	else:
		if Input.is_action_pressed("Shift"):
			deselect.set_selected(false)
			selected_players.erase(deselect)
			return
		for other_player in selected_players.duplicate():
			other_player.set_selected(false)
			selected_players.erase(other_player)
	
	if groups.is_editting:
		configure_group_editting_buttons()
	
	var can_do_player_actions = selected_players.size() > 0
	
	edit_player.disabled = not can_do_player_actions
	delete_player.disabled = not can_do_player_actions
	


func on_player_clicked(player: PlayerBanner):
	if player not in selected_players:
		set_selected_player(player)
		if create_type == "edit":
			# Refresh the data
			set_create_mode(1, "edit")
	else:
		if create_mode == 1 and create_type == "edit":
			toast.toast("Stop editing to deselect!", 3,
				{"modulate" = Color(1.0, 0.3, 0.3, 1.0)})
		else:
			set_selected_player(null, player)

## Mode 0: default; mode 1: text edit - type "create", "edit"
func set_create_mode(mode: int, type: String = "create"):
	var mode_changed = true
	if mode == create_mode: mode_changed = false
	create_mode = mode
	create_type = type
	var current_selected_players = selected_players
	var single_player
	if current_selected_players.size() == 1:
		single_player = current_selected_players[0]
	
	var new_mouse_filter = Control.MOUSE_FILTER_IGNORE if mode == 0 else Control.MOUSE_FILTER_STOP
	
	var ids_uneditable = type == "edit" and current_selected_players.size() != 1
	create_first_name.editable = not ids_uneditable
	create_last_name.editable = not ids_uneditable
	create_date_of_birth.editable = not ids_uneditable
	create_back_picker.disabled = ids_uneditable
	
	for node in create.get_children():
		if node.name == "BackPicker": continue
		node.modulate = new_player.modulate if type == "create" else edit_player.modulate
	
	for line_edit in line_edits:
		line_edit.mouse_filter = new_mouse_filter
		if mode == 1:
			if create_type == "create":
				line_edit.text = ""
			else:
				if single_player:
					var name_split = single_player.player_name.split(".")
					var text = {
						"FirstName": name_split[0],
						"LastName": name_split[1],
						"DateOfBirth": single_player.birthdate.replace("_", "/"),
						"MMR": str(player_data[single_player.file_name].mmr),
					}
					line_edit.text = text[line_edit.name]
				else:
					line_edit.text = "*Mix"
			on_text_changed(line_edit.text, line_edit)
		if line_edit.name == "MMR":
			line_edit.get_node("Info").mouse_filter = new_mouse_filter
	if create_type == "create":
		create_back_picker.selected_image = ""
	else:
		if single_player:
			create_back_picker.selected_image = player_data[single_player.file_name].back
	
	
	
	if mode_changed:
		create.modulate = Color(1, 1, 1, 1 - mode)
		
		create_cancel.mouse_filter = new_mouse_filter
		create_confirm.mouse_filter = new_mouse_filter
		create_back_picker.mouse_filter = new_mouse_filter
		
		
		var btn_mouse_filter = Control.MOUSE_FILTER_STOP if mode == 0 else Control.MOUSE_FILTER_IGNORE
		
		edit_player.mouse_filter = btn_mouse_filter
		delete_player.mouse_filter = btn_mouse_filter
		new_player.mouse_filter = btn_mouse_filter
		var tween = create_tween()
		tween.set_parallel()
		
		tween.tween_property(
			create, "modulate", Color(1, 1, 1, mode), 0.5
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		tween.tween_property(
			options, "modulate", Color(1, 1, 1, 1 - mode), 0.5
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		tween.play()


func create_player_banner(player_name: String, birthdate: String):
	var player = player_template.instantiate()
	player.modulate = Color(1, 1, 1, 0)
	player.birthdate = birthdate
	
	players.add_child(player)
	player.pressed.connect(on_player_clicked.bind(player))
	player.set_player_name(player_name)
	var tween = create_tween()
	tween.tween_property(
		player, "modulate", Color(1, 1, 1, 1), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.play()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	PlayerBacks.init()
	
	#set_new_player_mode(0)
	edit_player.disabled = true
	delete_player.disabled = true
	
	if not DirAccess.dir_exists_absolute(players_path):
		DirAccess.make_dir_recursive_absolute(players_path)
	
	var temp_player_data = {}
	var i = 0
	for player_name in DirAccess.get_files_at(players_path):
		var file_path = players_path + "/" + player_name
		var without_extention = player_name.substr(0, len(player_name) - 7)
		var without_birthdate = without_extention.substr(0, len(without_extention) - 8)
		var birthdate = without_extention.substr(len(without_extention) - 7, -1)
		
		var file = FileAccess.open(file_path, FileAccess.READ_WRITE)
		var data = file.get_var()
		if typeof(data) != TYPE_DICTIONARY:
			data = {"mmr": 0, "back": "", "last_played": []}
			
			file.seek(0)
			file.store_var(data)
			
			toast.toast("The player: %s was corrupted!" % without_extention, 5 + i, {
				"modulate" = Color(1, 0.4, 0.4)})
		if "last_played" not in data:
			data.last_played = []
			
			file.seek(0)
			file.store_var(data)
		
		temp_player_data[without_extention] = data
		create_player_banner(without_birthdate, birthdate)
		i += 1
	
	player_data = temp_player_data
	is_loaded = true
	loaded.emit()
	
	set_create_mode(0)
	
	new_player.pressed.connect(set_create_mode.bind(1, "create"))
	edit_player.pressed.connect(set_create_mode.bind(1, "edit"))
	create_cancel.pressed.connect(func():
		set_create_mode(0)
		create_back_picker.set_enabled(false)
	)
	
	for line_edit in line_edits:
		line_edit.text_changed.connect(on_text_changed.bind(line_edit))
	
	#while true:
		#await get_tree().create_timer(5).timeout
		#if title.visible: continue
		#for player_name in player_data:
			#var file = FileAccess.open("%s/%s.player" % [players_path, player_name], FileAccess.WRITE)
			#await get_tree().create_timer(1).timeout
			#file.store_var(player_data[player_name])


func on_text_changed(new_text: String, line_edit: LineEdit) -> void:
	var character_limit = line_edit.get_node("CharacterLimit")
	character_limit.text = str(len(new_text)) + "/" + str(line_edit.max_length)


func _on_confirm_pressed() -> void:
	var current_selected_players = selected_players
	var single_player: PlayerBanner
	if current_selected_players.size() == 1:
		single_player = current_selected_players[0]
	var current_create_type = create_type
	
	var first_name = create_first_name.text
	var last_name = create_last_name.text
	var date_of_birth = create_date_of_birth.text
	var mmr_text = create_mmr.text
	var back = create_back_picker.selected_image
	
	
	var regex = RegEx.new()
	regex.compile(r"(\d\d)/\d\d\d\d")
	var new_name = first_name + "." + last_name
	var dob_result = regex.search(date_of_birth)
	var mmr = mmr_text.to_int()
	
	var is_single = single_player or current_create_type == "create"
	
	var file_name
	var birthdate: String
	if is_single:
		if first_name == "":
			toast.toast("Does this person not have a name??! Please enter a first name", 4,
			{"modulate" = Color(1.0, 0.3, 0.3, 1.0)})
			return
		if not dob_result:
			toast.toast("Invalid date of birth! Use the format\nMM/YYYY and pad with 0's", 3,
				{"modulate" = Color(1.0, 0.3, 0.3, 1.0)})
			return
		birthdate = dob_result.strings[0].replace("/", "_")
		
		file_name = new_name + "." + birthdate
		if (file_name in player_data) and (create_type == "edit" and file_name != single_player.file_name):
			toast.toast("Name/birthdate pair already used!", 4, {"modulate" = Color(1.0, 0.3, 0.3, 1.0)})
			return
		if not new_name.is_valid_filename() or "." in first_name or "." in last_name:
			toast.toast("Do not use following characters in name:\n" + r' : / \ ? * " | % < > .', 4,
				{"modulate" = Color(1.0, 0.3, 0.3, 1.0)})
			return
		if int(dob_result.strings[1]) > 12 or int(dob_result.strings[1]) < 1:
			toast.toast("Invalid month! Enter a number 1-12", 3,
				{"modulate" = Color(1.0, 0.3, 0.3, 1.0)})
			return
	
	set_create_mode(0)
	
	if not is_single and mmr_text == "*Mix":
		return
	
	if mmr < 0:
		toast.toast("Invalid MMR! Enter a number >0", 3,
			{"modulate" = Color(1.0, 0.3, 0.3, 1.0)})
		return
	
	if current_create_type == "edit":
		if single_player:
			var file_path = players_path + "/" + file_name + ".player"
			var data = {"mmr": mmr, "back": back, "last_played": []}
			if file_name != single_player.file_name:
				var old_file_name = single_player.file_name
				var old_file_path = players_path + "/" + old_file_name + ".player"
				DirAccess.rename_absolute(old_file_path, file_path)
				for group in groups.group_data:
					if old_file_name in group:
						group.erase(old_file_name)
						group.append(file_name)
				player_data.erase(old_file_name)
			
			single_player.set_player_name(new_name)
			single_player.birthdate = birthdate
			
			var file = FileAccess.open(file_path, FileAccess.WRITE)
			
			file.store_var(data)
			player_data[file_name] = data
		else:
			for player in selected_players:
				var this_file_name = player.file_name
				var this_file_path = players_path + "/" + this_file_name + ".player"
				var this_file = FileAccess.open(this_file_path, FileAccess.WRITE)
				
				var last_data = player_data[this_file_name]
				
				var data = {"mmr": mmr, "back": last_data.back, "last_played": last_data.last_played}
				
				data = data.duplicate()
				data.back = player_data[this_file_name].back
				
				this_file.store_var(data)
				player_data[this_file_name] = data
				
				var file = FileAccess.open(this_file_path, FileAccess.WRITE)
			
				file.store_var(data)
				player_data[file_name] = data
			
	else:
		create_player_banner(new_name, birthdate)

var is_holding_delete_button = false
var delete_player_start_hold_time := -1
const REQUIRED_HOLD_TIME := 5.0

var hold_transparency_tween: Tween

## Mode 0: default; mode 1: delete timer
func set_delete_button_mode(mode: int):
	if hold_transparency_tween and hold_transparency_tween.is_running():
		hold_transparency_tween.kill()
	
	
	hold_transparency_tween = create_tween()
	hold_transparency_tween.set_parallel()
	hold_transparency_tween.tween_property(
		delete_player_text, "modulate", Color(1, 1, 1, 1 - mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	hold_transparency_tween.tween_property(
		delete_player_hold_text, "modulate", Color(1, 1, 1, mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	hold_transparency_tween.play()

func destroy_player(player_deleting: PlayerBanner):
	DirAccess.remove_absolute(players_path + "/" + player_deleting.file_name + ".player")
	player_data.erase(player_deleting.file_name)
	
	for group in groups.group_data.values():
		group.erase(player_deleting.file_name)
	
	set_selected_player(null, player_deleting)
	set_delete_button_mode(0)
	
	var tween = create_tween()
	tween.tween_property(
		player_deleting, "modulate", Color(1, 1, 1, 0), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	var order = player_deleting.get_index()
	
	await tween.finished
	
	player_deleting.queue_free()
	
	var space = Control.new()
	space.offset_bottom = 0
	space.custom_minimum_size = Vector2(0, 60)
	players.add_child(space)
	players.move_child(space, order)
	
	tween = create_tween()
	tween.tween_property(
		space, "custom_minimum_size", Vector2(0, 0), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN)
	
	tween.play()
	
	await tween.finished
	
	space.queue_free()

var delete_tick := 0

func _on_delete_player_button_down() -> void:	
	delete_tick += 1
	delete_tick %= 10000
	var this_delete_tick = delete_tick
	
	
	delete_player_start_hold_time = Time.get_ticks_msec()
	is_holding_delete_button = true
	
	set_delete_button_mode(1)
	
	await get_tree().create_timer(REQUIRED_HOLD_TIME).timeout
	if not is_holding_delete_button or delete_tick != this_delete_tick: return
	
	# <--- PLAYER HAS BEEN DELETED ---> #
	
	for player in selected_players:
		destroy_player(player)


func _on_delete_player_button_up() -> void:
	# Will get set to false if the delete is followed throught with
	if is_holding_delete_button:
		set_delete_button_mode(0)
		is_holding_delete_button = false


func _process(_delta: float):
	if not is_holding_delete_button: return
	 
	@warning_ignore("integer_division")
	var time_elapsed = float(Time.get_ticks_msec() - delete_player_start_hold_time) / 1000.0
	delete_player_hold_text.text = "[%.1f]" % time_elapsed
	
	delete_player_hold_progress.anchor_right = time_elapsed / REQUIRED_HOLD_TIME
