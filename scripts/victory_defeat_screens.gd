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

func change_scene(scene_path: String):
	# Check if path is empty
	if scene_path == "":
		print("ERROR: Empty scene path provided")
		return
	
	# Check if file exists
	if not ResourceLoader.exists(scene_path):
		print("ERROR: Scene file does not exist at path: ", scene_path)
		return
	
	# Load the scene
	var loaded_scene = load(scene_path)
	if loaded_scene == null:
		print("ERROR: Failed to load scene from path: ", scene_path)
		return
	
	# Instantiate and add to tree
	var new_scene = loaded_scene.instantiate()
	if new_scene == null:
		print("ERROR: Failed to instantiate scene")
		return
	
	get_tree().root.add_child(new_scene)
	queue_free()
	
func _on_next_level_victory_button_up() -> void:
	next_level.emit()
	print('siguiente')
func _on_back_menu_victory_button_up() -> void:
	menu_pressed.emit()
	change_scene(game_menu_path)

func _on_back_menu_defeat_button_up() -> void:
	menu_pressed.emit()
	change_scene(game_menu_path)
	
func _on_retry_level_defeat_pressed() -> void:
	retry_level.emit()
	print('repito')
