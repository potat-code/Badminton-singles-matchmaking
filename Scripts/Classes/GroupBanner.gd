class_name GroupBanner extends AnimatedButton

@onready var groups_container: Control = get_node("/root/Main/Title/Main/Groups")
@onready var groups: VBoxContainer = groups_container.get_node("Scroll/Control/Main")
@onready var players: Control = get_node("/root/Main/Title/Main/Players")

@onready var selection_indicator: ColorRect = $SelectionIndicator
@onready var title_text: Label = $Title/Main
@onready var content: RichTextLabel = $Content

var ignore_deselect := false
var group_name = null
var index := 1
var tween: Tween

func set_selected(on: bool = true):
	if on:
		for group in groups.get_children():
			if group == self: continue
			group.set_selected(false)
	
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

func set_group_name(new_name: String):
	group_name = new_name
	title_text.text = new_name

func _process(_delta: float):
	if not (group_name and groups_container.group_data and group_name in groups_container.group_data):
		content.text = '[font_size="34"][i]Loading...[/i][/font_size]'
		return
	
	var total_mmr = 0
	var players_num = 0
	for player_file_name in groups_container.group_data[group_name]:
		total_mmr += players.player_data[player_file_name].mmr
		players_num += 1
	
	var avg_mmr
	
	if players_num != 0:
		@warning_ignore("integer_division")
		avg_mmr = total_mmr / players_num
	
	var players_text = str(players_num)
	var mmr_text = str(avg_mmr if avg_mmr else "???")
	var format_string = '[font_size="34"]Players: [b] {0} [/b] | Avg. MMR: [b] {1} [/b][/font_size]'
	content.text = format_string.format([players_text, mmr_text])
