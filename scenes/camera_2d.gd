extends Camera2D

var shake_strength := 0.0

func shake(amount: float):
	shake_strength = amount

func _process(_delta):
	if shake_strength > 0:
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		shake_strength *= 0.85

		if shake_strength < 0.1:
			shake_strength = 0
			offset = Vector2.ZERO
