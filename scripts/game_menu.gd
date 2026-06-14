extends TextureRect

@export var game_scene_path = "res://scenes/game.tscn"
@export var game_level_selection_path = "res://scenes/game_level_selection.tscn"
@export var game_menu_path = "res://scenes/game_menu.tscn"

func _on_button_play_button_up() -> void:
	print("bip")
	bootGameScene()

func _on_button_settings_button_up() -> void:
	print("bip")

func _on_button_selectlevel_button_up() -> void:
	Transition.change_scene_to(game_level_selection_path)

func bootGameScene():
	Transition.change_scene_to(game_scene_path)

func _on_button_backtomenu_button_up() -> void:
	Transition.change_scene_to(game_menu_path)
