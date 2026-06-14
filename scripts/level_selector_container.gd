extends GridContainer

var level_folder_path = "res://levels/"  # Cambia a tu ruta correcta
var buttons_folder_path = "res://assets/pieces/"
var level_files: Array = []
var textures_level_select: Array= []

func _ready():
	level_files = get_level_files()
	print("Niveles encontrados: ", level_files)
	textures_level_select = get_button_textures()
	var level_num=0
	# Crear botones para cada nivel
	for level in level_files:
		var button = TextureButton.new()
		button.texture_normal=textures_level_select[level]
		button.text = level.get_basename()
		add_child(button)
		level_num+=1

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
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if not dir.current_is_dir():
				continue
			if level_files.size() > 0 and file_name.ends_with("Piece.png"):
				textures.append(file_name)
			elif  level_files.size() > 6 and file_name.ends_with("Column.png"):
				textures.append(file_name)
			elif level_files.size() > 12 and file_name.ends_with("Row.png"):
				textures.append(file_name)
			elif level_files.size() > 18 and file_name.ends_with("Adjacent.png"):
				textures.append(file_name)
			file_name = dir.get_next()
		
		dir.list_dir_end()
	else:
		print("Error: No se pudo abrir la carpeta: ", level_folder_path)
	
	return textures
