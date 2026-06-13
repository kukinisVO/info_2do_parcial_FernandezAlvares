extends TextureRect

@onready var score_label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label = $MarginContainer/HBoxContainer/counter_label
@onready var type_label = $MarginContainer/HBoxContainer/type_label

var current_score = 0
var current_count = 0
var current_type = 0

enum Objetivo { SCORE, COLOR}

func _ready() -> void:
	var grid = $".".get_parent().get_node("grid")
	if grid:
		grid.score_changed.connect(update_score)
		grid.counter_changed.connect(update_counter)
		grid.init_labels.connect(init_labels)  

func init_labels(type:int, base_score:int, limit:int, objective_value:int, objective_color:String) -> void:
	current_type = type
	current_count = limit
	current_score = base_score
	counter_label.text = str(current_count)
	score_label.text = str(current_score)

	var text = ""
	if current_type == Objetivo.SCORE:
		text = "Goal: %d" % objective_value 

	elif current_type == Objetivo.COLOR:
		text = "Goal %d %s" % [objective_value, objective_color]

	else:
		text = "Goal %d " % objective_value
	type_label.text = text

func update_score(nuevo_puntaje: int) -> void:
	current_score = nuevo_puntaje
	score_label.text = str(current_score)

func update_counter(restantes: int, _total:int) -> void:
	current_count = restantes
	counter_label.text = str(current_count)
