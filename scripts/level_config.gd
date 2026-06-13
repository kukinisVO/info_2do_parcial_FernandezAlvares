class_name LevelConfig
extends Resource

enum Objetivo { SCORE, COLOR}

@export var name: String = "Nivel 1"
@export var type: Objetivo = Objetivo.SCORE
@export var value: int = 1000            # puntaje meta, o cantidad a recolectar
@export var color: String = "blue"       # solo si objetivo_tipo == RECOLECTAR_COLOR
@export var moves_limit: int = 20          # 0 = sin límite de movimientos
@export var time_limit: int = 0              # 0 = sin límite de tiempo
@export var available_colors: Array[String] = [
	"blue", "green", "light_green", "pink", "yellow", "orange",
]
@export var points_per_unit: int = 10
