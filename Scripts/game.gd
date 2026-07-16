extends Control

@export var player_template: PackedScene
@export var verses_label_template: PackedScene
@onready var toast: Control = %Toast

@onready var title: Node2D = %Title
@onready var groups = title.get_node("Main/Groups")
@onready var game: Node2D = %Game
@onready var players: Control = title.get_node("Main/Players")
@onready var title_name: Label = $Title/ContentFitter/Name

@onready var find_match: Control = $FindMatch
@onready var find_match_players: VBoxContainer = $FindMatch/Scroll/Control/Main
@onready var find_match_button: AnimatedButton = $FindMatchButton

@onready var match_player_with_random: AnimatedButton = $FindMatch/Options/MatchPlayerWithRandom
@onready var match_two_players: AnimatedButton = $FindMatch/Options/MatchTwoPlayers
@onready var match_two_random: AnimatedButton = $FindMatch/Options/MatchTwoRandom

@onready var matches: Control = $Matches
@onready var matches_scroll: VBoxContainer = $Matches/Scroll/Control/Main
@onready var mark_score: AnimatedButton = $Matches/MarkScore
@onready var mark_score_main: Control = $Matches/MarkScore/Main
@onready var player_one_score: LineEdit = $Matches/MarkScore/Main/PlayerOne
@onready var player_two_score: LineEdit = $Matches/MarkScore/Main/PlayerTwo
@onready var mark_score_cancel: AnimatedButton = $Matches/MarkScore/Main/Cancel

const MMR_GAIN_LABEL = preload("uid://bftqjd8x63gvx")

var selected_players = []

var players_path = "user://Save/Players"

var mode_tween: Tween
var current_mode := -1

## Stores players' filename in this group
var local_group_data: Array = []
## Stores player_file_name: MatchBanner. Stores bother players in the banner as keys.
var matchup_data = {}
## Stores player_file_name (String): other_player_file_name (String)
var player_match_data = {}
var selected_matchup: PlayerBanner

var mark_score_tween: Tween
var current_mark_score_mode = -1
var mark_score_data = []

const LAST_PLAYED_HISTORY_SIZE = 3

func get_descendants(parent: Node):
	var descendants = []
	for child in parent.get_children():
		descendants.append(child)
		descendants.append_array(get_descendants(child))
	
	return descendants

## Classes which should always use mouse filter ignore
var MFI_CLASSES = [ "Label", "RichTextLabel", "ColorRect", "TextureRect" ]

## Sets the mouse filter of the passed note and all its descendants to the new mouse filter
func set_mouse_filters(node: Node, new_mouse_filter: Control.MouseFilter, includeRoot: bool):
	for child: Node in get_descendants(node):
		if child.get_class() in MFI_CLASSES or child.name == "Title":
			child.mouse_filter = Control.MOUSE_FILTER_IGNORE
		else:
			child.mouse_filter = new_mouse_filter
	
	if includeRoot:
		node.mouse_filter = new_mouse_filter


## Mode 0 (false): Ongoing matches; Mode 1 (true): Find matches
func set_mode(mode):
	if typeof(mode) == TYPE_BOOL:
		mode = 1 if mode else 0
	
	if mode == current_mode: return
	current_mode = mode
	
	if mode_tween and mode_tween.is_running():
		mode_tween.kill()
	
	set_mouse_filters(find_match, Control.MOUSE_FILTER_STOP if mode == 1 else Control.MOUSE_FILTER_IGNORE, true)
	
	mode_tween = create_tween()
	mode_tween.set_parallel()
	
	mode_tween.tween_property(
		matches, "modulate", Color(1, 1, 1, 1 - mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	mode_tween.tween_property(
		find_match, "modulate", Color(1, 1, 1, mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	mode_tween.play()


func set_player_options_enabled():
	var num_selected = selected_players.size()
	match_two_random.disabled = not is_matchup_available(false)
	match_player_with_random.disabled = num_selected != 1 or selected_players[0].file_name in player_match_data
	match_two_players.disabled = num_selected != 2 or (
		selected_players[0].file_name in player_match_data) or (
		selected_players[1].file_name in player_match_data)


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
	
	set_player_options_enabled()


func on_player_clicked(player: PlayerBanner):
	if player not in selected_players:
		set_selected_player(player)
	else:
		set_selected_player(null, player)


func create_player_banner(player_name: String, birthdate: String, parent: Control = find_match_players):
	var player = player_template.instantiate()
	player.modulate = Color(1, 1, 1, 0)
	player.birthdate = birthdate
	
	parent.add_child(player)
	player.set_player_name(player_name)
	
	var tween = create_tween()
	tween.tween_property(
		player, "modulate", Color(1, 1, 1, 1), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.play()
	
	return player


const MAX_MATCH_ATTEMPTS := 200
const MAX_MMR_DIFFERENCE := 10_000


func is_matchup_available(play_toast = true) -> bool:
	@warning_ignore("integer_division")
	var matched_count := player_match_data.size() / 2
	var remaining_players := local_group_data.size() - matched_count
	
	if remaining_players < 2:
		if play_toast:
			toast.toast("No matchups available!", 3.0, {
				"modulate": Color(1, 0.3, 0.3)
			})
		return false

	return true


func get_available_players() -> Array:
	var available_players = []
	
	for file_name in local_group_data:
		if not player_match_data.has(file_name):
			available_players.append(file_name)
	
	return available_players


func get_random_unmatched_player() -> String:
	var available_players := get_available_players()
	
	if available_players.is_empty():
		return ""
	
	return available_players.pick_random()


func calculate_match_probability(first_data, other_data, first_year, other_year, other_file_name):
	var mmr_diff = abs(first_data.mmr - other_data.mmr)
	
	var history_pos = first_data.last_played.find(other_file_name)
	if history_pos == -1:
		history_pos = LAST_PLAYED_HISTORY_SIZE
	
	var history_weight := (
		float(history_pos) / float(LAST_PLAYED_HISTORY_SIZE)
	)
	
	var age_weight := clampf( 1.0 - 0.12 * abs(first_year - other_year),
		0.0,
		1.0
	)
	
	var mmr_weight := clampf( 0.7 + 0.3 * (1.0 - pow(1.0 - mmr_diff / float(MAX_MMR_DIFFERENCE), 5)),
		0.0,
		1.0
	)
	
	return history_weight * age_weight * mmr_weight


func find_match_for_player(first_file_name: String, first_data) -> String:
	var first_year := int(first_file_name.split(".")[-1].split("_")[-1])
	
	var candidates := get_available_players()
	candidates.erase(first_file_name)
	candidates.shuffle()
	
	var leniency := 100
	var attempts := 0
	
	while attempts < MAX_MATCH_ATTEMPTS:
		attempts += 1
		
		for other_file_name in candidates:
			var other_data = players.player_data[other_file_name]
			
			var mmr_diff = abs(first_data.mmr - other_data.mmr)
			
			if mmr_diff > leniency:
				continue
			
			var other_year := int(
				other_file_name.split(".")[-1].split("_")[-1]
			)
			
			var probability = calculate_match_probability(
				first_data,
				other_data,
				first_year,
				other_year,
				other_file_name
			)
			
			if randf() < probability:
				return other_file_name
		
		leniency += 100
	
	return ""


func save_player_data(file_name: String, player_data: Variant) -> bool:
	var path = "%s/%s.player" % [players_path, file_name]
	
	var file := FileAccess.open(path, FileAccess.WRITE)
	
	if file == null:
		push_error("Failed to save player data: %s" % path)
		return false
	file.store_var(player_data)
	return true


func update_last_played(first_file_name: String, second_file_name: String, first_data, second_data) -> void:
	first_data.last_played.push_front(second_file_name)
	
	second_data.last_played.push_front(first_file_name)
	
	while first_data.last_played.size() > 3:
		first_data.last_played.pop_back()
	
	while second_data.last_played.size() > 3:
		second_data.last_played.pop_back()


func create_matchup_with(first_file_name):
	var first_data = players.player_data[first_file_name]
	
	var second_file_name = find_match_for_player(first_file_name, first_data)
	if second_file_name.is_empty():
		toast.toast("Unable to find a valid matchup! Unknown error <＿　＿)>", 3.0, {
			"modulate": Color(1, 0.3, 0.3)
		})
		return
	var second_data = players.player_data[second_file_name]
	
	update_last_played(
		first_file_name,
		second_file_name,
		first_data,
		second_data
	)
	
	if not save_player_data(first_file_name, first_data):
		toast.toast("Something failed! I have no idea why... [295]", 3.0, {
			"modulate": Color(1, 0.3, 0.3)
		})
		return
	
	
	if not save_player_data(second_file_name, second_data):
		toast.toast("Something failed! I have no idea why... [301]", 3.0, {
			"modulate": Color(1, 0.3, 0.3)
		})
		return
	
	var first_first_name = first_file_name.split(".")[0]
	var second_first_name = second_file_name.split(".")[0]
	
	toast.toast("Matched %s and %s!" % [first_first_name, second_first_name], 4)
	create_match_banner(first_file_name, second_file_name)

## >>>>>>>--- CONNECTIONS --->>>>>>> ##

func _on_match_two_random_pressed() -> void:
	if not is_matchup_available():
		return
	
	var first_file_name := get_random_unmatched_player()
	if first_file_name.is_empty():
		return
	
	create_matchup_with(first_file_name)


func _on_match_player_with_random_pressed() -> void:
	create_matchup_with(selected_players[0].file_name)


func _on_match_two_players_pressed() -> void:
	var first_file_name = selected_players[0].file_name
	var second_file_name = selected_players[1].file_name
	
	var first_first_name = first_file_name.split(".")[0]
	var second_first_name = second_file_name.split(".")[0]
	
	toast.toast("Matched %s and %s!" % [first_first_name, second_first_name], 4)
	create_match_banner(first_file_name, second_file_name)

## <<<<<<<--- CONNECTIONS ---<<<<<<< ##

func set_selected_matchup(matchup: PlayerBanner):
	if matchup:
		matchup.set_selected(true)
		if selected_matchup:
			selected_matchup.set_selected(false)
		selected_matchup = matchup
	else:
		if selected_matchup:
			selected_matchup.set_selected(false)
		selected_matchup = null
	
	mark_score.disabled = false if matchup else true


func on_matchup_player_clicked(matchup: PlayerBanner):
	if matchup != selected_matchup:
		#if matchup.file_name != player_match_data[selected_matchup.file_name]:
			# Refresh
			#set_mark_score_mode(1)
		var last_file_name = "???"
		if selected_matchup:
			last_file_name = selected_matchup.file_name
		set_selected_matchup(matchup)
		if last_file_name in player_match_data and matchup.file_name != player_match_data[last_file_name]:
			set_mark_score_mode(0)
		mark_score.disabled = false
	else:
		set_selected_matchup(null)
		mark_score.disabled = true
		set_mark_score_mode(0)


func create_match_banner(player_file_name: String, player_file_name_2: String):
	player_match_data[player_file_name] = player_file_name_2
	player_match_data[player_file_name_2] = player_file_name
	
	var container = HBoxContainer.new()
	container.custom_minimum_size = Vector2(0, 60)
	container.clip_children = true
	matches_scroll.add_child(container)
	matchup_data[player_file_name] = container
	matchup_data[player_file_name_2] = container
	
	var split = player_file_name.split(".")
	var player = create_player_banner(split[0] + "." + split[1], split[2], container)
	
	var verses_label = verses_label_template.instantiate()
	container.add_child(verses_label)
	
	var split2 = player_file_name_2.split(".")
	var player2 = create_player_banner(split2[0] + "." + split2[1], split2[2], container)
	
	player.pressed.connect(on_matchup_player_clicked.bind(player))
	player2.pressed.connect(on_matchup_player_clicked.bind(player2))
	
	player.context = "Matchup"
	player2.context = "Matchup"
	
	set_player_options_enabled()


func set_mark_score_mode(mode: int, use_button_pressed: bool = false):
	if use_button_pressed:
		mode = mark_score.button_pressed
	if mode == current_mark_score_mode: return
	current_mark_score_mode = mode
	mark_score.button_pressed = mode == 1
	
	set_mouse_filters(mark_score, Control.MOUSE_FILTER_STOP if mode == 1 else Control.MOUSE_FILTER_IGNORE, false)
	
	if mode:
		var current_selected_matchup: PlayerBanner = selected_matchup
		
		var other_player_file_name = player_match_data[current_selected_matchup.file_name]
		
		var p1_first_name = current_selected_matchup.file_name.split(".")[0]
		player_one_score.text = ""
		player_one_score.placeholder_text = "Mark %s's score..." % p1_first_name
		
		var other_first_name = other_player_file_name.split(".")[0]
		player_two_score.text = ""
		player_two_score.placeholder_text = "Mark %s's score..." % other_first_name
		
		var first_banner = current_selected_matchup.get_parent().get_children()[0]
		var order = 0 if current_selected_matchup == first_banner else 1
		mark_score_data = [current_selected_matchup.file_name, other_player_file_name, order]
	
	if mark_score_tween and mark_score_tween.is_running():
		mark_score_tween.kill()
	
	mark_score_tween = create_tween()
	mark_score_tween.set_parallel()
	
	mark_score_tween.tween_property(
		mark_score_main, "modulate", Color(1, 1, 1, mode), 0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	
	mark_score_tween.play()

var last_valid_text_data = {}
## Makes sure the only text in the passed line edit is a valid integer.
func sanitize_text(new_text: String, line_edit: LineEdit, was_submitted: bool = false):
	var last_valid_text = ""
	var last_caret_position = 0
	if line_edit in last_valid_text_data.keys():
		last_valid_text = last_valid_text_data[line_edit][0]
		last_caret_position = last_valid_text_data[line_edit][1]
	else:
		last_valid_text_data[line_edit] = ["", 0]
	
	if not new_text.is_valid_int() and new_text != "":
		line_edit.text = last_valid_text
		line_edit.caret_column = last_caret_position
		#var regex = RegEx.new()
		#regex.compile(r"\d*")
		#var match_strings = regex.search(new_text).strings
		#match_strings.append_array(regex.search(new_text, 1).strings)
		#if match_strings.size() >= 1:
			#line_edit.text = match_strings[0]
			#line_edit.caret_column = len(new_text)
	
	if was_submitted and line_edit.text != "":
		line_edit.text = str(int(line_edit.text))
	
	last_valid_text_data[line_edit][0] = line_edit.text


#func round_away(number: float):
	#if number < 0:
		#return floor(number)
	#else:
		#return ceil(number)


func _on_confirm_pressed() -> void:
	var current_mark_score_data = mark_score_data
	var order = current_mark_score_data.pop_at(-1)
	if order == 1:
		current_mark_score_data.reverse()
	
	set_mark_score_mode(0)
	
	var first_file_name = current_mark_score_data[0]
	var second_file_name = current_mark_score_data[1]
	
	var first_score = int(player_one_score.text)
	var second_score = int(player_two_score.text)
	var first_data = players.player_data[first_file_name]
	var second_data = players.player_data[second_file_name]
	#var first_mmr
	#var second_mmr
	#
	#first_mmr = players.player_data[first_file_name].mmr
	#second_mmr = players.player_data[second_file_name].mmr
	#
	#var margin = abs(first_score - second_score)
	#var base = 8.0 * sqrt(margin)
	#var expected = 1.0 / (1 + 10.0 ** ((second_mmr - first_mmr) / 4000.0))
	#var actual = 1.0 if first_score > second_score else 0.0
	#var gain = base * (actual - expected) * 4.0
	#gain = clamp(round(gain), -50, 50)
	#gain = int(gain)
	
	var first_gain_data = GlickoHandler.get_gain(first_score, second_score, first_data, second_data)
	var second_gain_data = GlickoHandler.get_gain(second_score, first_score, second_data, first_data)
	
	var temp_old_mmr = players.player_data[first_file_name].mmr
	print("%s mmr += %d (%d -> %d)" % [
		first_file_name, first_gain_data.mmr, temp_old_mmr, temp_old_mmr + first_gain_data.mmr
	])
	print("%s mmr += %d (%d -> %d)" % [
		second_file_name, second_gain_data.mmr, temp_old_mmr, temp_old_mmr + second_gain_data.mmr
	])
	
	players.player_data[first_file_name].mmr += first_gain_data.mmr
	players.player_data[second_file_name].mmr += second_gain_data.mmr
	
	players.player_data[first_file_name].rd += first_gain_data.rd
	players.player_data[second_file_name].rd += second_gain_data.rd
	
	save_player_data(first_file_name, players.player_data[first_file_name])
	save_player_data(second_file_name, players.player_data[second_file_name])
	
	var main_tween = create_tween()
	main_tween.set_parallel()
	
	var matchup = matchup_data[first_file_name]
	var i = 0
	
	var matchup_destroy_ignore = []
	var player_banners: Array[PlayerBanner] = [matchup.get_children()[0], matchup.get_children()[2]]
	if order == 1:
		player_banners.reverse()
	
	for player_banner: PlayerBanner in player_banners:
		var this_gain = first_gain_data.mmr if i == 0 else second_gain_data.mmr
		var this_sign = sign(this_gain)
		
		var cover = ColorRect.new()
		if this_sign == 1:
			cover.color = Color(0.3, 1, 0.3)
		elif this_sign == -1:
			cover.color = Color(1, 0.3, 0.3)
		else:
			cover.color = Color(0.5, 0.5, 0.5)
		cover.anchor_right = 1.0
		cover.offset_right = 0
		cover.offset_bottom = 0
		matchup_destroy_ignore.append(cover)
		player_banner.add_child(cover)
		
		var mmr_gain_label: Label = MMR_GAIN_LABEL.instantiate()
		if i == 0:
			mmr_gain_label.text = "%dMMR (%s%d)" % [
				first_data.mmr + this_gain, "+" if this_sign == 1 else "", this_gain
			]
		else:
			mmr_gain_label.text = "%dMMR (%s%d)" % [
				first_data.mmr + this_gain, "+" if this_sign == 1 else "", this_gain
			]
		mmr_gain_label.anchor_bottom = 1.5
		mmr_gain_label.anchor_left = 0
		mmr_gain_label.anchor_top = 1.5
		mmr_gain_label.anchor_right = 1.0
		
		main_tween.tween_property(
			cover, "anchor_bottom", 1.0, 0.5
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_delay(0.1 * i)
		i += 1
		
		main_tween.tween_property(
			mmr_gain_label, "anchor_bottom", 0.5, 0.5
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_delay(0.1 * i)
		main_tween.tween_property(
			mmr_gain_label, "anchor_top", 0.5, 0.5
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_delay(0.1 * i)
		
		@warning_ignore("integer_division")
		main_tween.tween_property(
			mmr_gain_label, "anchor_bottom", -0.5, 0.5
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_delay(2 + 0.1 * (i / 2))
		@warning_ignore("integer_division")
		main_tween.tween_property(
			mmr_gain_label, "anchor_top", -0.5, 0.5
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART).set_delay(2 + 0.1 * (i / 2))
		player_banner.add_child(mmr_gain_label)
		
		i += 1
	
	
	main_tween.play()
	await main_tween.finished
	
	player_banners[0].mark_for_deletion()
	player_banners[1].mark_for_deletion()
	var descendants = get_descendants(player_banners[0])
	var second_descendants = get_descendants(player_banners[1])
	descendants.append_array(second_descendants)
	for child: Control in descendants:
		if child in matchup_destroy_ignore: continue
		child.queue_free()
	
	var fade_tween = create_tween()
	fade_tween.tween_property(
		matchup, "modulate", Color.TRANSPARENT, 0.5
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
	
	fade_tween.play()
	await fade_tween.finished
	
	for node in get_descendants(matchup):
		node.queue_free()
	
	var shrink_tween = create_tween()
	shrink_tween.tween_property(
		matchup, "custom_minimum_size", Vector2.ZERO, 0.5
	).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUART)
	
	shrink_tween.play()
	await shrink_tween.finished
	
	# >>>>>>>--- CLEAN UP --->>>>>>>
	
	matchup.queue_free()
	matchup_data.erase(current_mark_score_data[0])
	matchup_data.erase(current_mark_score_data[1])
	player_match_data.erase(current_mark_score_data[1])
	player_match_data.erase(current_mark_score_data[0])
	
	# <<<<<<<--- CLEAN UP ---<<<<<<<

func init(group_name: String):
	match_player_with_random.disabled = true
	match_two_players.disabled = true
	mark_score.disabled = true
	title_name.text = group_name
	
	# >>>>>>>--- RESET --->>>>>>>
	
	player_match_data = {}
	matchup_data = {}
	mark_score_data = []
	for matchup: Node in matches_scroll.get_children():
		if not matchup.is_class("HBoxContainer"):
			continue
		matchup.queue_free()
	
	# <<<<<<<--- RESET ---<<<<<<<
	
	set_mark_score_mode(0)
	set_mode(0)
	find_match_button.set_pressed_no_signal(false)
	var data = groups.group_data[group_name]
	var temp_group_data = []
	
	for player_file_name in data:
		temp_group_data.append(player_file_name)
		var split = player_file_name.split(".")
		var player = create_player_banner(split[0] + "." + split[1], split[2])
		player.pressed.connect(on_player_clicked.bind(player))
		player.context = "FindMatch"
		
	local_group_data = temp_group_data

var last_button_pressed = false

func _ready():
	find_match_button.toggled.connect(set_mode)
	# mark_score.button_pressed updates after this is called, so:
	# ALERT: MAKE SURE YOU SET last_button_pressed PROPERLY!!!!!!!!!!!!!
	#mark_score.pressed.connect(func():
		#last_button_pressed = !last_button_pressed
		#set_mark_score_mode(1 if last_button_pressed else 0)
	#)
	mark_score.pressed.connect(set_mark_score_mode.bind(-1, true))
	mark_score_cancel.pressed.connect(set_mark_score_mode.bind(0))
	
	player_one_score.text_changed.connect(sanitize_text.bind(player_one_score))
	player_two_score.text_changed.connect(sanitize_text.bind(player_two_score))
	
	player_one_score.text_submitted.connect(sanitize_text.bind(player_one_score, true))
	player_two_score.text_submitted.connect(sanitize_text.bind(player_two_score, true))


func _process(_delta):
	if player_one_score in last_valid_text_data:
		last_valid_text_data[player_one_score][1] = player_one_score.caret_column
	if player_two_score in last_valid_text_data:
		last_valid_text_data[player_two_score][1] = player_two_score.caret_column
