extends GridContainer

var level_folder_path = "res://levels/"  # Cambia a tu ruta correcta
var buttons_folder_path = "res://assets/pieces/"
@export var game_scene_path = "res://scenes/game.tscn"
var level_files: Array = []
var textures_level_select: Array= []

func _ready():
	level_files = get_level_files()
	print("Niveles encontrados: ", level_files)
	textures_level_select = get_button_textures()
	print("texturas necesarias: ", textures_level_select)
	var level_num=0
	# Crear botones para cada nivel
	for level in level_files:
		var button = TextureButton.new()
		var texture_path = textures_level_select[level_num]
		var texture = load(texture_path) 
		button.texture_normal = texture
		# Connect signal
		button.button_up.connect(_on_level_button_up.bind(level_num+1,button))
		button.mouse_entered.connect(_on_button_hover.bind(button))
		button.mouse_exited.connect(_on_button_unhover.bind(button))
		button.button_down.connect(_on_button_down.bind(button))
		if level_num+1 > GlobalVariable.highest_level+1:
			button.disabled = true
			button.modulate = Color(0.4, 0.4, 0.4, 1.0)
		add_child(button)
		level_num += 1

func _on_level_button_up(level_index: int, button: TextureButton) -> void:
	print("Selected level: ", level_index)
	button.modulate = Color(1.2, 1.2, 1.2, 1.0)
	GlobalVariable.current_level=level_index
	GlobalVariable.level_selected=true
	Transition.change_scene_to(game_scene_path)
	
func _on_button_hover(button: TextureButton) -> void:
	if button.disabled != true:
		button.modulate = Color(1.2, 1.2, 1.2, 1.0)

func _on_button_unhover(button: TextureButton) -> void:
	if button.disabled != true:
		button.modulate = Color.WHITE

func _on_button_down(button: TextureButton) -> void:
	button.modulate = Color(0.7, 0.7, 0.7, 1.0)

func get_level_files() -> Array:
	var levels = []
	var dir = DirAccess.open(level_folder_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				levels.append(file_name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("Error: No se pudo abrir la carpeta: ", level_folder_path)
	
	return levels
	
func get_button_textures() -> Array:
	var textures = []
	var dir = DirAccess.open(buttons_folder_path)
	var total_levels = level_files.size()
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir() and not file_name.contains(".import") :
				# Guardar solo la RUTA, no el recurso cargado
				var texture_path = buttons_folder_path + file_name
				
				if file_name.contains("Piece") and total_levels >= 1:
					textures.append(texture_path) 
				elif file_name.contains("Column") and total_levels > 6:
					textures.append(texture_path)
				elif file_name.contains("Row") and total_levels > 12:
					textures.append(texture_path)
				elif file_name.contains("Adjacent") and total_levels > 18:
					textures.append(texture_path)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("Error: No se pudo abrir la carpeta: ", buttons_folder_path)
	
	print("Texturas encontradas: ", textures)  # Ahora mostrará solo rutas
	return textures
