extends Node2D

@export var color: String
@export var texture_row : Texture2D
@export var texture_column : Texture2D
@export var texture_adjacent : Texture2D

@export var special_spawn_chance = 0.1 

enum PieceType {
	NORMAL,
	HORIZONTAL,
	VERTICAL,
	ADJACENT
}

var matched = false
var piece_type = PieceType.NORMAL
var is_special = false

# TODO (PARCIAL · M3): para las piezas especiales podrías guardar aquí su tipo
# (por ejemplo, "fila", "columna" o "bomba") y exponer un método que dispare su
# efecto sobre el tablero cuando se active.
func _ready():
	# Randomly determine if this piece is special
	if randf() < special_spawn_chance:
		make_special()
		

func make_special():
	is_special = true
	var types = [PieceType.HORIZONTAL, PieceType.VERTICAL, PieceType.ADJACENT]
	piece_type = types[randi() % types.size()]
	
	match piece_type:
		PieceType.HORIZONTAL:
			$Sprite2D.texture = texture_row  
		PieceType.VERTICAL:
			$Sprite2D.texture = texture_column
		PieceType.ADJACENT:
			$Sprite2D.texture = texture_adjacent  
			
func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)
	
func on_destroyed(grid, x, y):
	if not is_special:
		return false  # Normal piece, no special effect
	
	match piece_type:
		PieceType.HORIZONTAL:
			# Destroy entire row
			for i in range(grid.width):
				if grid.all_pieces[i][y] and grid.all_pieces[i][y] != self and grid.all_pieces[i][y].color == self.color:
					grid.all_pieces[i][y].matched = true
			return true
			
		PieceType.VERTICAL:
			# Destroy entire column
			for j in range(grid.height):
				if grid.all_pieces[x][j] and grid.all_pieces[x][j] != self and grid.all_pieces[x][j].color == self.color:
					grid.all_pieces[x][j].matched = true
			return true
			
		PieceType.ADJACENT:
			var radius = 2  # 3x3 area (radius 1 = 1 cell in each direction)
			for i in range(max(0, x - radius), min(grid.width, x + radius + 1)):
				for j in range(max(0, y - radius), min(grid.height, y + radius + 1)):
					if grid.all_pieces[i][j] and grid.all_pieces[i][j] != self:
						if grid.all_pieces[i][j].color == self.color:
							grid.all_pieces[i][j].matched = true
			return true
	
	return false

# Check if this piece can participate in a match
func can_match():
	return true  # All pieces can match, but specials have extra effects
