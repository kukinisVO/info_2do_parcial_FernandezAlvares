extends Node

const SAVE_FILE := "user://saves.json"
var level_selected: bool = false
var current_level: int = 0
var best_score: int = 0
var highest_level: int = 0

var counted: int

func _ready():
	load_save()

func load_save():
	if not FileAccess.file_exists(SAVE_FILE):
		return 
	var file = FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		return 
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_text) == OK:
		var data = json.data
		highest_level = data.get("highest_level", 0)
		current_level = data.get("current_level", 1)
		best_score = data.get("best_score", 0)
