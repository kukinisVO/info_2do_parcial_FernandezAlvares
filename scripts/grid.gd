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

# piece array
var possible_pieces = [
	preload("res://scenes/blue_piece.tscn"),
	preload("res://scenes/green_piece.tscn"),
	preload("res://scenes/light_green_piece.tscn"),
	preload("res://scenes/pink_piece.tscn"),
	preload("res://scenes/yellow_piece.tscn"),
	preload("res://scenes/orange_piece.tscn"),
]
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

# === PUNTAJE (B1) y CONTADOR (B2) ===
# Contrato sugerido para comunicarte con el HUD (top_ui.gd). No es obligatorio usar
# señales, pero ayuda a mantener la UI desacoplada de la lógica del tablero:
#   signal score_changed(nuevo_puntaje: int)
#   signal counter_changed(restantes: int)        # movimientos o segundos, tú decides
#   signal game_finished(gano: bool)
# TODO (PARCIAL · B1/B2): declara aquí el puntaje y el contador (y sus señales, si las usas).

#propio calls
@onready var audio_controller : Node2D = get_node("../AudioController")
##combo
var current_combo = 0
var combo = false
# Called when the node enters the scene tree for the first time.
func _ready():
	state = MOVE
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()

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
	# TODO (PARCIAL · B2): un intercambio válido consume una jugada. Decide dónde
	# descontar el contador: aquí, o en destroy_matched() solo si hubo combinación.
	if not move_checked:
		find_matches()

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

func _process(delta):
	if state == MOVE:
		touch_input()
	if Input.is_key_pressed(KEY_R):
		restart_grid()

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
				while k < width and all_pieces[k][j] != null and all_pieces[k][j].color == current_color:
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
					audio_controller.sfx_match(4)
				else:
					var column = pieces[0].x
					for y in range(height):
						if all_pieces[column][y] != null:
							all_pieces[column][y].matched = true
							all_pieces[column][y].dim()
					audio_controller.sfx_match(4)
			
			5:
				for x in range(width):
					for y in range(height):
						if all_pieces[x][y] != null and all_pieces[x][y].color == color:
							all_pieces[x][y].matched = true
							all_pieces[x][y].dim()
				audio_controller.sfx_match(5)
	
func destroy_matched():
	var was_matched = false
	for i in width:
		for j in height:
			var piece = all_pieces[i][j]
			if piece != null and piece.matched:
				was_matched = true
				all_pieces[i][j].queue_free()
				all_pieces[i][j] = null
	
	move_checked = true
	if was_matched:
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
		# El tablero quedó estable: no hay más combinaciones en cascada.
	# TODO (PARCIAL · M1): verifica si se cumplió o falló el objetivo del nivel
	# (puntaje meta, piezas recolectadas, etc.) y dispara victoria o derrota.
	# TODO (PARCIAL · M2): comprueba si todavía existe alguna jugada válida; si no,
	# rebaraja el tablero hasta que haya al menos una.
	# Board is stable, check if there are valid moves
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
	
	# Reset variables
	state = MOVE
	move_checked = false
	current_combo = 0
	piece_one = null
	piece_two = null
	
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
	while i < width and all_pieces[i][y] != null and all_pieces[i][y].color == color:
		horizontal_length += 1
		i += 1
	# Check left
	i = x - 1
	while i >= 0 and all_pieces[i][y] != null and all_pieces[i][y].color == color:
		horizontal_length += 1
		i -= 1
	
	if horizontal_length >= 3:
		return true
	
	# Check vertical line
	var vertical_length = 1
	# Check down
	var j = y + 1
	while j < height and all_pieces[x][j] != null and all_pieces[x][j].color == color:
		vertical_length += 1
		j += 1
	# Check up
	j = y - 1
	while j >= 0 and all_pieces[x][j] != null and all_pieces[x][j].color == color:
		vertical_length += 1
		j -= 1
	
	return vertical_length >= 3

func _on_destroy_timer_timeout():
	destroy_matched()

func _on_collapse_timer_timeout():
	collapse_columns()

func _on_refill_timer_timeout():
	refill_columns()
	
func game_over():
	state = WAIT
	# TODO (PARCIAL · B3): muestra la pantalla final (victoria o derrota), detén la
	# entrada del jugador y ofrece reiniciar la partida. Emite game_finished(gano).
	# TODO (PARCIAL · M4): guarda el progreso (nivel alcanzado) y el mejor puntaje
	# en disco (user://) para conservarlos entre sesiones.

# TODO (PARCIAL · M2): funciones sugeridas para detectar el bloqueo del tablero.
# func hay_jugadas_validas() -> bool:
# func rebarajar() -> void:
