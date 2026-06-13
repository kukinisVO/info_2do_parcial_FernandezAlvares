extends Node2D

# state machine
enum {WAIT, MOVE}
var state

# grid
@export var width: int
@export var height: int
@export var x_start: int
@export var y_start: int
@export var offset: int
@export var y_offset: int

# pieces
var color_pieces = {
	"blue": preload("res://scenes/blue_piece.tscn"),
	"green":preload("res://scenes/green_piece.tscn"),
	"light_green":preload("res://scenes/light_green_piece.tscn"),
	"pink":preload("res://scenes/pink_piece.tscn"),
	"yellow":preload("res://scenes/yellow_piece.tscn"),
	"orange":preload("res://scenes/orange_piece.tscn"),
}

var possible_pieces = []
# current pieces in scene
var all_pieces = []

# swap back
var piece_one = null
var piece_two = null
var last_place = Vector2.ZERO
var last_direction = Vector2.ZERO
var move_checked = false

# touch variables
var first_touch = Vector2.ZERO
var final_touch = Vector2.ZERO
var is_controlling = false

# === Temporizadores del ciclo destruir → colapsar → rellenar ===
# Son nodos hijos de "grid"; el editor conecta sus señales "timeout" a este script.
@onready var destroy_timer: Timer = $destroy_timer
@onready var collapse_timer: Timer = $collapse_timer
@onready var refill_timer: Timer = $refill_timer

#SIGNALS
signal score_changed(nuevo_puntaje: int)
signal counter_changed(restantes: int, total:int)
signal init_labels(type:int, base_score:int, limit:int, value:int, color:String)  
#signal game_finished(gano: bool)

#propio calls
@onready var audio_controller : Node2D = get_node("../AudioController")
##combo
var current_combo = 0
var combo = false

const SAVE_FILE := "user://saves.json"

@export var levels  = {
	1 : load("res://levels/1.tres"),
	2 : load("res://levels/2.tres"),
	3 : load("res://levels/3.tres"),
	4 : load("res://levels/4.tres"),
	5 : load("res://levels/5.tres"),
	6 : load("res://levels/6.tres")
}
enum Objetivo { SCORE, COLOR}

@export var level_data: LevelConfig
var level_index: int = 1
var highest_level: int = 1
var score: int = 0
var best_score: int = 0
var counted: int = 0
var objective_name: String
var objective_type
var objective_value: int
var objective_color: String
var points_per_unit:int 
var moves_limit: int 
var available_colors

# Called when the node enters the scene tree for the first time.
func _ready():
	load_progress()
	set_level()
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()

func level_up():
	if level_index >= levels.size():
		level_index = 0 #until we use the winning screen
		#game_over()
		#return
	level_index +=1
	highest_level = max(highest_level, level_index)
	reset()
	await get_tree().process_frame
	save_progress()
	set_level()
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	

func set_level():
	level_data = levels.get(level_index)
	set_level_data()
	init_labels.emit(objective_type,score, moves_limit, objective_value, objective_color)

func set_level_data():
	possible_pieces.clear()
	objective_name = level_data.name
	objective_type = level_data.type
	objective_value = level_data.value
	objective_color = level_data.color
	points_per_unit = level_data.points_per_unit
	moves_limit = level_data.moves_limit
	counted = moves_limit
	available_colors = level_data.available_colors
	for color in available_colors:
		possible_pieces.append(color_pieces.get(color))
	
func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start - offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	
func in_grid(column, row):
	return column >= 0 and column < width and row >= 0 and row < height
	
func spawn_pieces():
	for i in width:
		for j in height:
			# random number
			var rand = randi_range(0, possible_pieces.size() - 1)
			# instance 
			var piece = possible_pieces[rand].instantiate()
			# repeat until no matches
			var max_loops = 100
			var loops = 0
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			# fill array with pieces
			all_pieces[i][j] = piece
			piece.add_to_group("pieces")

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].color == color and all_pieces[i - 2][j].color == color:
				return true
	# check down
	if j> 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].color == color and all_pieces[i][j - 2].color == color:
				return true
	return false

func touch_input():
	var mouse_pos = get_global_mouse_position()
	var grid_pos = pixel_to_grid(mouse_pos.x, mouse_pos.y)
	if Input.is_action_just_pressed("ui_touch") and in_grid(grid_pos.x, grid_pos.y):
		first_touch = grid_pos
		is_controlling = true
		
	# release button
	if Input.is_action_just_released("ui_touch") and in_grid(grid_pos.x, grid_pos.y) and is_controlling:
		is_controlling = false
		final_touch = grid_pos
		touch_difference(first_touch, final_touch)

func swap_pieces(column, row, direction: Vector2):
	if counted <= 0:
		game_over()
		return
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	if first_piece == null or other_piece == null:
		return
	# swap
	state = WAIT
	store_info(first_piece, other_piece, Vector2(column, row), direction)
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	#first_piece.position = grid_to_pixel(column + direction.x, row + direction.y)
	#other_piece.position = grid_to_pixel(column, row)
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	# TODO (PARCIAL · M3): si alguna de las piezas intercambiadas es especial,
	# actívala aquí (su efecto reemplaza a la búsqueda normal de combinaciones).
	if not move_checked:
		find_matches()
		counted -= 1
		counter_changed.emit(counted, moves_limit)

func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction

func swap_back():
	if piece_one != null and piece_two != null:
		swap_pieces(last_place.x, last_place.y, last_direction)
	state = MOVE
	move_checked = false

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	# should move x or y?
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))
	if abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))

func _process(_delta):
	if state == MOVE:
		touch_input()

func find_matches():
	# TODO (PARCIAL · M3): aquí es donde se decide qué piezas forman cada combinación.
	# Para crear piezas especiales necesitas conocer el LARGO de cada línea: una de 4
	# genera una pieza de línea (fila/columna) y una de 5 una bomba de color. El chequeo
	# actual solo mira el "centro" de tríos; probablemente tengas que recorrer las
	# líneas completas para distinguir combinaciones de 3, 4 y 5.
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				# detect horizontal matches
				if (
					i > 0 and i < width -1 
					and 
					all_pieces[i - 1][j] != null and all_pieces[i + 1][j]
					and 
					all_pieces[i - 1][j].color == current_color and all_pieces[i + 1][j].color == current_color
				):
					all_pieces[i - 1][j].matched = true
					all_pieces[i - 1][j].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i + 1][j].matched = true
					all_pieces[i + 1][j].dim()
				# detect vertical matches
				if (
					j > 0 and j < height -1 
					and 
					all_pieces[i][j - 1] != null and all_pieces[i][j + 1]
					and 
					all_pieces[i][j - 1].color == current_color and all_pieces[i][j + 1].color == current_color
				):
					all_pieces[i][j - 1].matched = true
					all_pieces[i][j - 1].dim()
					all_pieces[i][j].matched = true
					all_pieces[i][j].dim()
					all_pieces[i][j + 1].matched = true
					all_pieces[i][j + 1].dim()
					
	destroy_timer.start()	

func destroy_matched():
	var was_matched = false
	var matched:int = 0
	var color_matched:int = 0
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and all_pieces[i][j].matched:
				was_matched = true
				matched += 1
				if objective_type == Objetivo.COLOR and all_pieces[i][j].color == objective_color:
					color_matched +=1
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
	move_checked = true
	if was_matched:
		if objective_type == Objetivo.COLOR:
			score += color_matched
		else: 
			score += matched * points_per_unit
		score_changed.emit(score)
		if score >= objective_value:
			level_up()
			return
		collapse_timer.start()
		if current_combo == 0:
			audio_controller.sfx_swap("normal")
	else:
		swap_back()
		audio_controller.sfx_swap("invalid")

func collapse_columns():
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# look above
				for k in range(j + 1, height):
					if all_pieces[i][k] != null:
						all_pieces[i][k].move(grid_to_pixel(i, j))
						all_pieces[i][j] = all_pieces[i][k]
						all_pieces[i][k] = null
						break
	refill_timer.start()

func refill_columns():
	
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				# random number
				var rand = randi_range(0, possible_pieces.size() - 1)
				# instance 
				var piece = possible_pieces[rand].instantiate()
				# repeat until no matches
				var max_loops = 100
				var loops = 0
				while (match_at(i, j, piece.color) and loops < max_loops):
					rand = randi_range(0, possible_pieces.size() - 1)
					loops += 1
					piece = possible_pieces[rand].instantiate()
				add_child(piece)
				piece.position = grid_to_pixel(i, j - y_offset)
				piece.move(grid_to_pixel(i, j))
				# fill array with pieces
				all_pieces[i][j] = piece
				
	check_after_refill()

func check_after_refill():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null and match_at(i, j, all_pieces[i][j].color):
				find_matches()
				current_combo+=1
				print("combo! :", current_combo)
				audio_controller.sfx_match(current_combo)
				destroy_timer.start()
				return
	if score >= objective_value:
		level_up()
		return
	if counted <= 0:
		game_over()
		return
	# TODO (PARCIAL · M2): comprueba si todavía existe alguna jugada válida; si no,
	# rebaraja el tablero hasta que haya al menos una.
	current_combo=0
	state = MOVE
	move_checked = false

func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()
	
func game_over():
	print("GAMEOVER")
	state = WAIT
	# TODO (PARCIAL · B3): muestra la pantalla final (victoria o derrota), detén la
	# entrada del jugador y ofrece reiniciar la partida. Emite game_finished(gano).
	reset()
	await get_tree().process_frame
	save_progress()

func save_progress():
	var data = {
		"highest_level": highest_level,
		"current_level":level_index,
		"best_score": best_score
	}
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_progress():
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
		highest_level = data.get("highest_level", 1)
		var current_level = data.get("current_level", 1)
		level_index = current_level
		best_score = data.get("best_score", 0)
		print(level_index)
		print(best_score)

func reset():
	best_score = max(score, best_score)
	score = 0
	move_checked = false
	piece_one = null
	piece_two = null
	current_combo = 0
	for piece in get_tree().get_nodes_in_group("pieces"):
		piece.queue_free()
	
# TODO (PARCIAL · M2): funciones sugeridas para detectar el bloqueo del tablero.
# func hay_jugadas_validas() -> bool:
# func rebarajar() -> void:
