class_name NovaPulseEffect
extends Node2D

@export var duration: float = 0.45

var target_scale: float = 1.0


func setup(radius: float) -> void:
	target_scale = radius / 26.0


func _ready() -> void:
	scale = Vector2.ONE * target_scale * 0.12
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE * target_scale, duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(queue_free)
