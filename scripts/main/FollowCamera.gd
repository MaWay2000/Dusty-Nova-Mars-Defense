class_name FollowCamera
extends Camera2D

@export var shake_enabled: bool = true
@export var shake_decay: float = 16.0

var shake_strength: float = 0.0


func configure(bounds: Rect2) -> void:
	limit_left = int(bounds.position.x)
	limit_top = int(bounds.position.y)
	limit_right = int(bounds.end.x)
	limit_bottom = int(bounds.end.y)


func shake(strength: float = 8.0) -> void:
	if shake_enabled:
		shake_strength = maxf(shake_strength, strength)


func _process(delta: float) -> void:
	if shake_strength <= 0.05:
		offset = Vector2.ZERO
		shake_strength = 0.0
		return
	offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	shake_strength = move_toward(shake_strength, 0.0, shake_decay * delta)
