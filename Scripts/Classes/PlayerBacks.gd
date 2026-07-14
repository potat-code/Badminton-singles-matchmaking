class_name PlayerBacks extends Node


static var backs: Dictionary = {}
static var colors: Dictionary = {
	"BarfBag.jpg": Color(0.859, 0.776, 0.561, 1.0),
	"BlackHole.jpg": Color(0.169, 0.125, 0.282, 1.0),
	"Book.jpg": Color(0.016, 0.584, 0.69, 1.0),
	"Braceletty.jpg": Color(0.369, 0.882, 0.992, 1.0),
	"Bubble.jpg": Color(0.525, 0.929, 0.996, 1.0),
	"Cake.jpg": Color(0.612, 0.376, 0.345, 1.0),
	"Coiny.jpg": Color(0.996, 0.82, 0.322, 1.0),
	"EightBall.jpg": Color(0.565, 0.608, 0.718, 1.0),
	"Firey.jpg": Color(1.0, 0.659, 0.004, 1.0),
	"Foldy.jpg": Color(0.353, 0.796, 0.827, 1.0),
	"Fries.jpg": Color(0.953, 0.529, 0.286, 1.0),
	"Gaty.jpg": Color(0.725, 0.776, 0.992, 1.0),
	"Gelatin.jpg": Color(0.071, 0.843, 0.051, 1.0),
	"Grassy.jpg": Color(0.29, 0.898, 0.004, 1.0),
	"IceCube.jpg": Color(0.761, 0.831, 0.973, 1.0),
	"Leafy.jpg": Color(0.435, 0.949, 0.106, 1.0),
	"Liy.jpg": Color(0.631, 0.667, 0.961, 1.0),
	"Loser.jpg": Color(0.996, 0.882, 0.522, 1.0),
	"Marker.jpg": Color(0.58, 0.318, 1.0, 1.0),
	"Match.jpg": Color(1.0, 0.616, 0.235, 1.0),
	"Needle.jpg": Color(0.737, 0.796, 0.808, 1.0),
	"Nickel.jpg": Color(0.514, 0.686, 0.698, 1.0),
	"Pen.jpg": Color(0.114, 0.529, 0.992, 1.0),
	"Pencil.jpg": Color(1.0, 0.698, 0.039, 1.0),
	"Pin.jpg": Color(0.996, 0.4, 0.349, 1.0),
	"Rocky.jpg": Color(0.506, 0.553, 0.506, 1.0),
	"Ruby.jpg": Color(0.996, 0.098, 0.318, 1.0),
	"Saw.jpg": Color(0.996, 0.463, 0.62, 1.0),
	"Taco.jpg": Color(0.98, 0.839, 0.604, 1.0),
}

const BACKS_PREFIX = "res://Assets/Backs"
static var initialised = false

static func init():
	if initialised: return
	initialised = true
	
	for file_name in DirAccess.get_files_at("res://Assets/Backs"):
		var extention = file_name.split(".")[-1]
		if extention != "jpg": continue
		backs[file_name] = load(BACKS_PREFIX + "/" + file_name)
