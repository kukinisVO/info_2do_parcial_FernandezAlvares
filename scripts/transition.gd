extends CanvasLayer


@onready var color_rect: ColorRect = $BlackScreen
var scene_to_load: String
var color_rect_tween: Tween

func change_scene_to (scene_path: String) -> void:
	scene_to_load = scene_path
	fade_on_finish_func(_load_new_scene)
	
func _load_new_scene() -> void:
	get_tree().call_deferred("change_scene_to_file",scene_to_load)
	
func fade_on_finish_func(function:Callable) -> void:
	start_transition()
	color_rect_tween = create_tween().set_trans(Tween.TRANS_SINE)
	color_rect_tween.tween_property(color_rect, "modulate:a", 1.0, 0.2).connect("finished",function)
	color_rect_tween.chain().tween_property(color_rect,"modulate:a", 0.0,0.4)
	stop_transition()
	
func fade_in() -> void:
	start_transition()
	color_rect_tween = create_tween().set_trans(Tween.TRANS_SINE)
	color_rect_tween.tween_property(color_rect, "modulate:a", 1.0, 0.2)

func fade_out() -> void:
	color_rect_tween.chain().tween_property(color_rect,"modulate:a", 0.0,0.4)
	stop_transition()
	
func start_transition() -> void:
	if color_rect_tween:
		color_rect_tween.kill()
		print("You forcefully ended a transition")
	if get_tree().paused == true:
		print("You tried to start a transition in the middle of another")
	else: 
		get_tree().paused = true
	
func stop_transition() -> void:
	get_tree().paused=false
