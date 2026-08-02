class_name MarsArena
extends Node2D

@export var arena_size: Vector2 = Vector2(3600.0, 2200.0)
@export var background_color: Color = Color("8f3f2f")
@export var crater_color: Color = Color("6c3028")
@export var ridge_color: Color = Color("a64d35")
@export var decoration_seed: int = 7319
@export var crater_count: int = 42


func _ready() -> void:
	queue_redraw()


func get_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, arena_size)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, arena_size), background_color)
	var random := RandomNumberGenerator.new()
	random.seed = decoration_seed
	for index: int in crater_count:
		var position := Vector2(random.randf_range(80.0, arena_size.x - 80.0), random.randf_range(80.0, arena_size.y - 80.0))
		var radius := random.randf_range(24.0, 80.0)
		var color := crater_color if index % 3 else ridge_color
		draw_circle(position, radius, color)
		draw_arc(position + Vector2(radius * 0.12, radius * 0.08), radius * 0.72, 0.0, TAU, 24, color.darkened(0.14), 5.0)
	for x: float in range(120, int(arena_size.x), 260):
		draw_line(Vector2(x, 0.0), Vector2(x - 180.0, arena_size.y), Color(0.2, 0.08, 0.06, 0.08), 3.0)
