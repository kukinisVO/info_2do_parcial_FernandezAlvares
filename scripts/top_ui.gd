extends TextureRect

@onready var score_label : Label = $MarginContainer/HBoxContainer/score_label
@onready var counter_label : Label = $MarginContainer/HBoxContainer/counter_label
@onready var type_label  : Label = $MarginContainer/HBoxContainer/type_label

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
		


func init_labels(type:int, base_score:int, limit:int, objective_value:int, objective_color:String,nivel:int) -> void:
	current_count = limit
	current_score = base_score
	counter_label.text = str(current_count)
	score_label.text = "Score:\n%s" % current_score

	type_label.text = "Nivel:" + str(nivel) 

func update_score(nuevo_puntaje: int) -> void:
	current_score = nuevo_puntaje
	score_label.text = "Score:\n%s" % current_score
	
func update_counter(restantes: int, _total:int) -> void:
	var old_count = current_count
	current_count = restantes
	
	if restantes < old_count:
		var tween = create_tween().set_trans(Tween.TRANS_SINE)
		var original_color = counter_label.modulate
		tween.tween_property(counter_label, "modulate", Color.RED, 0.1)
		tween.tween_property(counter_label, "modulate", original_color, 0.3)
	
	counter_label.text = str(current_count)
