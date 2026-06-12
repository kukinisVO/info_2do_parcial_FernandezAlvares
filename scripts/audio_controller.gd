extends Node2D

@export var mute: bool = false

func sfx_soundtrack():
	if not mute:
		$soundtrack4.play()
		
func sfx_swap(type: String) -> void:
	if not mute:
		match type:
			"normal":
				$"piece_swap".play()
			"invalid":
				$"piece_!swap".play()
			"powered":
				$"piece_swap+".play()
			_:
				print("Wrong or unkown swap type sound")

func sfx_match(type: int) -> void:
	if not mute:
		match type:
			1:
				$"piece_match1".play()
			2:
				$"piece_match2".play()
			3:
				$"piece_match3".play()
			_:
				$"piece_match3".play()
