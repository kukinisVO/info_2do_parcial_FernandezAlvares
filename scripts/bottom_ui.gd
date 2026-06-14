extends TextureRect

@onready var type_label = $Label

var current_type = 0
enum Objetivo { SCORE, COLOR}

func _ready() -> void:
	var grid = get_parent().get_node("grid")
	if grid:
		grid.init_labels.connect(update_type)

func update_type(type:int, _base_score:int, _limit:int, objective_value:int, objective_color:String, _nivel:int) -> void:
	current_type = type
	var text = ""
	if current_type == Objetivo.SCORE:
		text = "Goal: %d" % objective_value 
	elif current_type == Objetivo.COLOR:
		text = "Goal %d %s" % [objective_value, objective_color]
	else:
		text = "Goal %d " % objective_value
	type_label.text = text
	print(text)
