extends ColorRect

@export var next_scene_path = ""
@export var game_menu_path = "res://scenes/game_menu.tscn"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass 

func _process(delta: float) -> void:
	pass

func change_scene(scene : String):
	var new_scene = load(scene).instantiate()
	get_tree().root.add_child(new_scene)
	queue_free()

func _on_next_level_victory_button_up() -> void:
	change_scene("")

func _on_back_menu_victory_button_up() -> void:
	change_scene(game_menu_path)

func _on_next_level_defeat_button_up() -> void:
	change_scene("")

func _on_back_menu_defeat_button_up() -> void:
	change_scene(game_menu_path)
	
