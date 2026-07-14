extends LineEdit

@onready var scroll: ScrollContainer = $"../Scroll"
@onready var scroll_main: VBoxContainer = $"../Scroll/Control/Main"

enum Matches {
	CONTAINS,
	LAST_NAME_STARTS,
	STARTS,
}

const PLAYER_BANNER_SIZE = 60.0

func _on_text_changed(new_text: String) -> void:
	if new_text == "": return
	
	var best_match = [null, null]
	new_text = new_text.to_lower()
	
	for player: PlayerBanner in scroll_main.get_children():
		if not player.is_class("Button"): continue
		
		var name_split: Array = player.player_name.split(".")
		var last_name = name_split[1].to_lower()
		var formatted_name = "{0} {1}".format(name_split).to_lower()
		
		if formatted_name.begins_with(new_text):
			if not best_match[0] or (best_match[0] and Matches.STARTS > best_match[1]):
				best_match[0] = player
				best_match[1] = Matches.STARTS
				break
		elif last_name.begins_with(new_text):
			if not best_match[0] or (best_match[0] and Matches.LAST_NAME_STARTS > best_match[1]):
				best_match[0] = player
				best_match[1] = Matches.LAST_NAME_STARTS
		elif new_text in formatted_name:
			if not best_match[0]:
				best_match[0] = player
				best_match[1] = Matches.CONTAINS
	
	
	if best_match[0]:
		# Align it to the center
		var new_scroll = best_match[0].position.y  - scroll.size.y / 2 + PLAYER_BANNER_SIZE / 2
		#scroll.scroll_vertical = new_scroll
		var tween = create_tween()
		tween.tween_property(
			scroll, "scroll_vertical", new_scroll, 0.25
		).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUART)
		tween.play()
