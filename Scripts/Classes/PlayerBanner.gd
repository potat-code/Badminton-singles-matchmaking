class_name PlayerBanner extends AnimatedButton

@onready var players_container: Control = get_node("/root/Main/Title/Main/Players")
@onready var players: VBoxContainer = players_container.get_node("Scroll/Control/Main")
@onready var groups: Control = get_node("/root/Main/Title/Main/Groups")
@onready var matches: Control = get_node("/root/Main/Game/Main")

@onready var selection_indicator: ColorRect = $SelectionIndicator
@onready var title_text: RichTextLabel = $Title/Main
@onready var content: RichTextLabel = $Content
@onready var back: TextureRect = $Back
@onready var back_color_rect: ColorRect = $Back/ColorRect
@onready var extra_info: Label = $ExtraInfo

## In the format "firstname.lastname". May be written to.
var player_name = null
## In the format "DD_YYYY". May be written to.
var birthdate = null
## Only used when removed. Do not write to.
var index := 1
## Private variable.
var tween: Tween
## Private variable.
var last_in_group_label_visibility = false
## Private variable.
var extra_info_tween: Tween

## Where this banner is. Values: "Main" - main select; "FindMatch" - find match screen; "Matchup" - matchup screen
var context = "Main"
var file_name = null

## Private variable.
var marked_for_deletion = false

## Stops visual updates for safety when descendants are being destroyed
func mark_for_deletion():
	marked_for_deletion = true


func set_selected(on: bool = true):
	#if on and deselect_others:
		#for player in players.get_children():
			#if player == self: continue
			#player.set_selected(false)
	
	if tween and tween.is_running():
		tween.kill()
	tween = create_tween()
	tween.tween_property(
		selection_indicator,
		"anchor_right",
		1 if on else 0,
		0.5
	).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.play()

## Expectf the format "firstname.lastname"
func set_player_name(new_name: String):
	player_name = new_name
	var regex = RegEx.new()
	regex.compile(r"(.*)\.(.*)")
	var name_match = regex.search(new_name)
	var strings = name_match.strings
	title_text.text = '[font_size="28"][b]' + strings[1] + " " + strings[2] + "[/b][/font_size]"

var modulate_set = false

func _process(_delta: float):
	if marked_for_deletion: return
	
	if not modulate_set and has_node("SelectBar"):
		modulate_set = true
		get_node("SelectBar").modulate = Color(1, 1, 1, 0.75)
	if not (player_name and players_container.player_data and
			file_name in players_container.player_data and
			birthdate and "back" in players_container.player_data[file_name] and
			players_container.player_data[file_name].back != null):
		
		var player_name_file_part = player_name if player_name else ""
		var birthdate_file_part = birthdate if birthdate else ""
		file_name = player_name_file_part + "." + birthdate_file_part
		content.text = '[font_size="17"][i]Loading...[/i][/font_size]'
		return
	
	var data = players_container.player_data[file_name]
	
	if data.back:
		back.modulate = Color.WHITE
		back_color_rect.modulate = Color.WHITE
		back.texture = PlayerBacks.backs[data.back]
		back_color_rect.color = PlayerBacks.colors[data.back]
	else:
		back.modulate = Color.TRANSPARENT
		back_color_rect.modulate = Color.TRANSPARENT
	var mmr_text = str(data.mmr)
	var format_string = '[font_size="17"]MMR: [b] {0} [/b] | Birthdate: [b] {1} [/b][/font_size]'
	content.text = format_string.format([mmr_text, birthdate.replace("_", "/")])
	
	var visibility
	if context == "Main":
		extra_info.text = "[ In group ]"
		visibility = groups.selected_group and file_name in groups.group_data[groups.selected_group.group_name]
	elif context == "FindMatch":
		extra_info.text = "[ In match ]"
		visibility = file_name in matches.player_match_data.keys()
	
	if visibility != last_in_group_label_visibility:
		last_in_group_label_visibility = visibility
		if extra_info_tween and extra_info_tween.is_running():
			extra_info_tween.kill()
		
		extra_info_tween = create_tween()
		extra_info_tween.tween_property(
			extra_info, "modulate", Color(1, 1, 1, 1 if visibility else 0), 0.5
		).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
		
		extra_info_tween.play()
