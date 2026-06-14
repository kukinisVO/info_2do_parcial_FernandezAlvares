extends Node2D

@export var color: String
@export var texture_row : Texture2D
@export var texture_column : Texture2D
@export var texture_adjacent : Texture2D
@export var special_spawn_chance = 0.1 

@onready var rainbow_effect: Sprite2D = $Overlay

enum PieceType {
	NORMAL,
	HORIZONTAL,
	VERTICAL,
	ADJACENT,
	RAINBOW
}

var matched = false
var piece_type = PieceType.NORMAL
var is_special = false

func _ready():
	if randf() < special_spawn_chance:
		make_special()

func make_special():
	is_special = true
	var types = [PieceType.HORIZONTAL, PieceType.VERTICAL, PieceType.ADJACENT, PieceType.RAINBOW]
	piece_type = types[randi() % types.size()]
	
	match piece_type:
		PieceType.HORIZONTAL:
			$Sprite2D.texture = texture_row  
		PieceType.VERTICAL:
			$Sprite2D.texture = texture_column
		PieceType.ADJACENT:
			$Sprite2D.texture = texture_adjacent
		PieceType.RAINBOW:
			blink_rainbow_texture()
			
func move(target):
	var move_tween = create_tween()
	move_tween.set_trans(Tween.TRANS_ELASTIC)
	move_tween.set_ease(Tween.EASE_OUT)
	move_tween.tween_property(self, "position", target, 0.4)

func dim():
	$Sprite2D.modulate = Color(1, 1, 1, 0.5)
	
func on_destroyed(grid, x, y):
	if not is_special:
		return false
	
	match piece_type:
		PieceType.HORIZONTAL:
			# Destruye toda la fila (mismo color)
			for i in range(grid.width):
				var piece = grid.all_pieces[i][y]
				if piece and piece != self and piece.color == color:
					piece.matched = true
					piece.dim()
			return true
			
		PieceType.VERTICAL:
			# Destruye toda la columna (mismo color)
			for j in range(grid.height):
				var piece = grid.all_pieces[x][j]
				if piece and piece != self and piece.color == color:
					piece.matched = true
					piece.dim()
			return true
			
		PieceType.ADJACENT:
			# Destruye mismo color en área de 5x5
			var radius = 2
			for i in range(max(0, x - radius), min(grid.width, x + radius + 1)):
				for j in range(max(0, y - radius), min(grid.height, y + radius + 1)):
					var piece = grid.all_pieces[i][j]
					if piece and piece != self and piece.color == color:
						piece.matched = true
						piece.dim()
			return true
		
		PieceType.RAINBOW:
			# Destruye all en radio
			var radius = 1
			for i in range(max(0, x - radius), min(grid.width, x + radius + 1)):
				for j in range(max(0, y - radius), min(grid.height, y + radius + 1)):
					var piece = grid.all_pieces[i][j]
					if piece and piece != self:
						piece.matched = true
						piece.dim()
			return true
	
	return false

func can_match():
	return true

func blink_rainbow_texture():
	
	var tween = create_tween()
	tween.set_loops() # infinite loop
	rainbow_effect.show()

	tween.tween_property(rainbow_effect, "modulate:a", 0.0, 2.0) # fade out
	tween.tween_property(rainbow_effect, "modulate:a", 1.0, 1.0) # fade in
