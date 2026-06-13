extends TextureRect

@export var game_scene_path = "res://scenes/game.tscn"

func _on_button_play_button_up() -> void:
	print("bip")
	bootGameScene()

func _on_button_settings_button_up() -> void:
	print("bip")

func _on_button_selectlevel_button_up() -> void:
	print("bip")

func bootGameScene():
	var new_scene = load(game_scene_path).instantiate()
	get_tree().root.add_child(new_scene)
	queue_free()
