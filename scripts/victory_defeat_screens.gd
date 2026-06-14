extends ColorRect

@export var next_scene_path = ""
@export var game_menu_path : String

signal next_level
signal retry_level
signal menu_pressed

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _process(_delta: float) -> void:
	pass
	
func _on_next_level_victory_button_up() -> void:
	next_level.emit()
	print('siguiente')
func _on_back_menu_victory_button_up() -> void:
	menu_pressed.emit()
	Transition.change_scene_to(game_menu_path)

func _on_back_menu_defeat_button_up() -> void:
	menu_pressed.emit()
	Transition.change_scene_to(game_menu_path)
	
func _on_retry_level_defeat_pressed() -> void:
	retry_level.emit()
	print('repito')
