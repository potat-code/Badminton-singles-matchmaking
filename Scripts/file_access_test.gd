@tool
extends EditorScript

# Globalize the path so the Editor knows exactly where to look on your PC
var dir_path = ProjectSettings.globalize_path("user://Save")

func configure_directories():
	# make_dir_recursive_absolute handles building the parent and subfolders all at once safely
	if not DirAccess.dir_exists_absolute(dir_path + "/Groups"):
		DirAccess.make_dir_recursive_absolute(dir_path + "/Groups")
		print("Made Groups directory!")
		
	if not DirAccess.dir_exists_absolute(dir_path + "/Players"):
		DirAccess.make_dir_recursive_absolute(dir_path + "/Players")
		print("Made Players directory!")
		
	print("Directories inside path: ", DirAccess.get_directories_at(dir_path))


func _run():
	configure_directories()
	
	# Create and safely close player 1
	var player = FileAccess.open(dir_path + "/Players/220901.potat.pot.player", FileAccess.WRITE)
	if player:
		player.store_var({"name": "potat pot", "id": "220901.potat.pot", "birthdate": "22/09/01", "mmr": 1450})
		player.flush() # Forces data to write immediately
	
	# Create and safely close player 2
	var player2 = FileAccess.open(dir_path + "/Players/220900.yazoo.yu.player", FileAccess.WRITE)
	if player2:
		player2.store_var({"name": "yazoo yu", "id": "220900.yazoo.yu", "birthdate": "22/09/00", "mmr": 955})
		player2.flush()

	# Create and safely close the group
	var group = FileAccess.open(dir_path + "/Groups/The yaz group.group", FileAccess.WRITE)
	if group:
		group.store_var(["220901.potat.pot", "220900.yazoo.yu"])
		group.flush()
		
	print("Files successfully written to: ", dir_path)
