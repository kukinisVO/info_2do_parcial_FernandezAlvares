extends Node2D

#region variables
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
	"blue": preload("res://scenes/pieces/blue_piece.tscn"),
	"green":preload("res://scenes/pieces/green_piece.tscn"),
	"light_green":preload("res://scenes/pieces/light_green_piece.tscn"),
	"pink":preload("res://scenes/pieces/pink_piece.tscn"),
	"yellow":preload("res://scenes/pieces/yellow_piece.tscn"),
	"orange":preload("res://scenes/pieces/orange_piece.tscn"),
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
#endregion

# === Temporizadores del ciclo destruir → colapsar → rellenar ===
# Son nodos hijos de "grid"; el editor conecta sus señales "timeout" a este script.
@onready var destroy_timer: Timer = $destroy_timer
@onready var collapse_timer: Timer = $collapse_timer
@onready var refill_timer: Timer = $refill_timer

#SIGNALS
signal score_changed(nuevo_puntaje: int)
signal counter_changed(restantes: int, total:int)
signal init_labels(type:int, base_score:int, limit:int, value:int, color:String, nivel:int)  
var game_finished: bool = false

#propio calls
var victory_overlay = preload("res://scenes/victory_popup.tscn")
var defeat_overlay = preload("res://scenes/defeat_popup.tscn")
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

@onready var camera = $".".get_parent().get_node("Camera2D")
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

func _colors_match(color1, color2) -> bool:
	return color1 == color2

# Called when the node enters the scene tree for the first time.
func _ready():
	load_progress()
	if GlobalVariable.level_selected:
		level_index = GlobalVariable.current_level
		GlobalVariable.level_selected = false
	set_level()
	state = MOVE
	seed(generate_daily_seed(level_index))
	all_pieces = make_2d_array()
	spawn_pieces()
	
func _process(_delta):
	if state == MOVE:
		touch_input()
	if Input.is_key_pressed(KEY_R):
		if not hay_jugadas_validas():
			print("Tablero bloqueado")
			restart_grid()
	if Input.is_key_pressed(KEY_T):
		imposibilizar_grid()

func generate_daily_seed(level: int) -> int:
	var date = Time.get_date_dict_from_system()
	var day_seed = (
		date.year * 10000 +
		date.month * 100 +
		date.day
	)

	return hash(str(day_seed) + "_" + str(level))

func level_retry():
	level_index -=1
	level_up()

func level_up():
	
	state = WAIT
	
	save_progress()
	if level_index >= levels.size():
		game_finished = true
		game_over()
		return
		
	level_index +=1
	highest_level = max(highest_level, level_index)
	
	set_level()
	# Stop any running timers
	if destroy_timer.is_stopped() == false:
		destroy_timer.stop()
	if collapse_timer.is_stopped() == false:
		collapse_timer.stop()
	if refill_timer.is_stopped() == false:
		refill_timer.stop()
	seed(generate_daily_seed(level_index))
	Transition.fade_on_finish_func(reset)  #restart grid and level values
	
	state = MOVE

func set_level():
	level_data = levels.get(level_index)
	set_level_data()
	init_labels.emit(objective_type,score, moves_limit, objective_value, objective_color,level_index)
	
	
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
			var rand = randi_range(0, possible_pieces.size() - 1)
			var piece = possible_pieces[rand].instantiate()
			var max_loops = 100
			var loops = 0
			
			# Evitar matches al spawnear (incluyendo rainbow)
			while (match_at(i, j, piece.color) and loops < max_loops):
				rand = randi_range(0, possible_pieces.size() - 1)
				loops += 1
				piece = possible_pieces[rand].instantiate()
			
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			all_pieces[i][j] = piece

func match_at(i, j, color):
	# check left
	if i > 1:
		if all_pieces[i - 1][j] != null and all_pieces[i - 2][j] != null:
			if _colors_match(all_pieces[i - 1][j].color, color) and _colors_match(all_pieces[i - 2][j].color, color):
				return true
	# 
	if j > 1:
		if all_pieces[i][j - 1] != null and all_pieces[i][j - 2] != null:
			if _colors_match(all_pieces[i][j - 1].color, color) and _colors_match(all_pieces[i][j - 2].color, color):
				return true
	return false
	
func store_info(first_piece, other_piece, place, direction):
	piece_one = first_piece
	piece_two = other_piece
	last_place = place
	last_direction = direction
	
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
		game_finished=false
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
	AudioController.sfx_swap("invalid")
	# TODO (PARCIAL · M3): si alguna de las piezas intercambiadas es especial,
	# actívala aquí (su efecto reemplaza a la búsqueda normal de combinaciones).
	if not move_checked:
		find_matches()
		counted -= 1
		counter_changed.emit(counted, moves_limit)

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


func find_matches():
	var horizontal_lines = []
	var vertical_lines = []
	# TODO (PARCIAL · M3): aquí es donde se decide qué piezas forman cada combinación.
	# Para crear piezas especiales necesitas conocer el LARGO de cada línea: una de 4
	# genera una pieza de línea (fila/columna) y una de 5 una bomba de color. El chequeo
	# actual solo mira el "centro" de tríos; probablemente tengas que recorrer las
	# líneas completas para distinguir combinaciones de 3, 4 y 5

	for j in height:
		var i = 0
		while i < width:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
					# detect horizontal matches
				var match_length = 1
				var k = i + 1
				while k < width and all_pieces[k][j] != null and _colors_match(all_pieces[k][j].color, current_color):
					match_length += 1
					k += 1
				
				if match_length >= 3:
					var match_pieces = []
					for x in range(i, i + match_length):
						match_pieces.append(Vector2(x, j))
					horizontal_lines.append({"pieces": match_pieces, "color": current_color, "length": match_length})
				
				i += match_length
			else:
				i += 1
	
	# detect vertical matches
	for i in width:
		var j = 0
		while j < height:
			if all_pieces[i][j] != null:
				var current_color = all_pieces[i][j].color
				var match_length = 1
				var k = j + 1
				while k < height and all_pieces[i][k] != null and all_pieces[i][k].color == current_color:
					match_length += 1
					k += 1
				
				if match_length >= 3:
					var match_pieces = []
					for y in range(j, j + match_length):
						match_pieces.append(Vector2(i, y))
					vertical_lines.append({"pieces": match_pieces, "color": current_color, "length": match_length})
				
				j += match_length
			else:
				j += 1
	
	process_match_lines(horizontal_lines)
	process_match_lines(vertical_lines)
	
	destroy_timer.start()

func process_match_lines(lines):
	for line in lines:
		var length = line["length"]
		var color = line["color"]
		var pieces = line["pieces"]
		
		match length:
			3:
				for pos in pieces:
					if all_pieces[pos.x][pos.y] != null:
						all_pieces[pos.x][pos.y].matched = true
						all_pieces[pos.x][pos.y].dim()
			
			4:
				# Check if horizontal or vertical
				if pieces[0].y == pieces[1].y: 
					var row = pieces[0].y
					for x in range(width):
						if all_pieces[x][row] != null:
							all_pieces[x][row].matched = true
							all_pieces[x][row].dim()
					AudioController.sfx_match(4)
				else:
					var column = pieces[0].x
					for y in range(height):
						if all_pieces[column][y] != null:
							all_pieces[column][y].matched = true
							all_pieces[column][y].dim()
					AudioController.sfx_match(4)
			
			5:
				for x in range(width):
					for y in range(height):
						if all_pieces[x][y] != null and _colors_match(all_pieces[x][y].color, color):
							all_pieces[x][y].matched = true
							all_pieces[x][y].dim()
				AudioController.sfx_match(5)
	
func destroy_matched():
	var was_matched = false
	var matched:int = 0
	var color_matched:int = 0
	
	var special_pieces = []
	for i in width:
		for j in height:
			var piece = all_pieces[i][j]
			if piece != null and piece.matched and piece.is_special:
				special_pieces.append({"piece": piece, "i": i, "j": j})
	
	for sp in special_pieces:
		sp.piece.on_destroyed(self, sp.i, sp.j)
		sp.piece.dim()
		
	await get_tree().create_timer(0.4).timeout
	
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
		if current_combo == 0:
			AudioController.sfx_swap("normal")
		if objective_type == Objetivo.COLOR:
			score += color_matched
		else: 
			score += matched * points_per_unit
		score_changed.emit(score)
		if score >= objective_value:
			level_up()
			return
		counter_changed.emit(GlobalVariable.counted, moves_limit)
		collapse_timer.start()
	else:
		swap_back()

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
				camera.shake(8 + current_combo * 5)
				print("combo! :", current_combo)
				AudioController.sfx_match(current_combo)
				destroy_timer.start()
				return
	if score >= objective_value:
		level_up()
		return
	if counted <= 0:
		game_finished=false
		game_over()
		return

	current_combo=0
	
	if not hay_jugadas_validas():
		print("No valid moves available. Restarting grid...")
		restart_grid()
	else:
		state = MOVE
		move_checked = false

func restart_grid():
	# Clear grid
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
	
	spawn_pieces()
	
	# This starts the board match-free
	await get_tree().process_frame 
	find_matches() 

func hay_jugadas_validas() -> bool:
	for i in width:
		for j in height:
			if all_pieces[i][j] == null:
				continue
			
			# Check horizontal swap
			if i < width - 1 and all_pieces[i + 1][j] != null:
				if would_create_match(i, j, Vector2(1, 0)):
					return true
			
			# Check vertical swap
			if j < height - 1 and all_pieces[i][j + 1] != null:
				if would_create_match(i, j, Vector2(0, 1)):
					return true
	print('Es un tablero sin swaps posibles')
	return false

func would_create_match(column, row, direction: Vector2) -> bool:
	var target_x = column + direction.x
	var target_y = row + direction.y
	
	# Temporal swap 
	var first_piece = all_pieces[column][row]
	var second_piece = all_pieces[target_x][target_y]
	
	all_pieces[column][row] = second_piece
	all_pieces[target_x][target_y] = first_piece
	
	# Check any match
	var has_match = false
	
	# Check around the swapped positions for matches
	if check_position_for_match(target_x, target_y):
		has_match = true
	
	if check_position_for_match(column, row):
		has_match = true
	
	# Swap back
	all_pieces[column][row] = first_piece
	all_pieces[target_x][target_y] = second_piece
	
	return has_match

func check_position_for_match(x, y) -> bool:
	if all_pieces[x][y] == null:
		return false
	
	var color = all_pieces[x][y].color
	
	# Check horizontal line
	var horizontal_length = 1
	# Check right
	var i = x + 1
	while i < width and all_pieces[i][y] != null and _colors_match(all_pieces[i][y].color, color):
		horizontal_length += 1
		i += 1
	# Check left
	i = x - 1
	while i >= 0 and all_pieces[i][y] != null and _colors_match(all_pieces[i][y].color, color):
		horizontal_length += 1
		i -= 1
	
	if horizontal_length >= 3:
		return true
	
	# Check vertical line
	var vertical_length = 1
	# Check down
	var j = y + 1
	while j < height and all_pieces[x][j] != null and _colors_match(all_pieces[x][j].color, color):
		vertical_length += 1
		j += 1
	# Check up
	j = y - 1
	while j >= 0 and all_pieces[x][j] != null and _colors_match(all_pieces[x][j].color, color):
		vertical_length += 1
		j -= 1
	
	return vertical_length >= 3

func imposibilizar_grid():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null

	# Necesitas al menos 4 colores
	if possible_pieces.size() < 4:
		push_error("Need at least 4 piece colors")
		return

	for i in width:
		for j in height:

			var index = (i + j) % 4

			var piece = possible_pieces[index].instantiate()

			add_child(piece)
			piece.position = grid_to_pixel(i, j)

			all_pieces[i][j] = piece

	print("Forced unsolvable board")

	if not hay_jugadas_validas():
		print("Confirmed: no valid moves")
		
	else:
		print("Pattern unexpectedly has moves")
#endregion

func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()

#region game over functions
func game_over():
	print("GAMEOVER")
	state = WAIT
	var overlay_to_show = victory_overlay if game_finished else defeat_overlay
	var overlay_instance = overlay_to_show.instantiate()
	overlay_instance.add_to_group("game_overlays")
	if overlay_instance.has_signal("next_level"):
		overlay_instance.next_level.connect(level_up)
	if overlay_instance.has_signal("retry_level"):
		overlay_instance.retry_level.connect(level_retry)
		
	get_tree().root.add_child(overlay_instance)
	save_progress()
	reset()
	await get_tree().process_frame

func save_progress():
	var data = {
		"highest_level": level_index,
		"current_level":level_index,
		"best_score": best_score
	}
	var file = FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()

func load_progress():
	level_index = GlobalVariable.current_level
	highest_level = GlobalVariable.highest_level
	best_score = GlobalVariable.best_score

func reset() :
	best_score = max(score, best_score)
	score = 0
	move_checked = false
	piece_one = null
	piece_two = null
	current_combo = 0
	restart_grid()
