class_name EnemySpawner
extends Node

signal enemy_defeated(experience_reward: int, death_position: Vector2)
signal enemy_hit
signal active_count_changed(count: int)

@export var enemy_scenes: Array[PackedScene]
@export var base_enemy_weights: Array[float] = [1.0, 0.0]
@export var spawn_margin: float = 120.0
@export var minimum_player_distance: float = 520.0
@export var maximum_active_enemies: int = 80

@onready var spawn_timer: Timer = $SpawnTimer

var player: Player
var camera: Camera2D
var arena_bounds: Rect2
var current_weights: Array[float] = []
var active_enemy_count: int = 0
var spawning_enabled: bool = false
var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)


func setup(target_player: Player, follow_camera: Camera2D, bounds: Rect2) -> void:
	player = target_player
	camera = follow_camera
	arena_bounds = bounds
	current_weights = base_enemy_weights.duplicate()


func configure_wave(spawn_interval: float, enemy_limit: int, weights: Array[float]) -> void:
	maximum_active_enemies = enemy_limit
	current_weights = weights.duplicate()
	spawning_enabled = true
	spawn_timer.wait_time = maxf(spawn_interval, 0.08)
	spawn_timer.start()


func pause_spawning() -> void:
	spawning_enabled = false
	spawn_timer.stop()


func stop_spawning() -> void:
	pause_spawning()


func _on_spawn_timer_timeout() -> void:
	if not spawning_enabled or active_enemy_count >= maximum_active_enemies:
		return
	_spawn_enemy()


func _spawn_enemy() -> void:
	var scene := _choose_enemy_scene()
	if scene == null:
		return
	var enemy := scene.instantiate() as BaseEnemy
	if enemy == null:
		return
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = _find_spawn_position()
	enemy.setup(player)
	enemy.died.connect(_on_enemy_died)
	enemy.hit.connect(func() -> void: enemy_hit.emit())
	active_enemy_count += 1
	active_count_changed.emit(active_enemy_count)


func _choose_enemy_scene() -> PackedScene:
	if enemy_scenes.is_empty():
		return null
	var total_weight := 0.0
	for index: int in enemy_scenes.size():
		total_weight += maxf(current_weights[index] if index < current_weights.size() else 1.0, 0.0)
	if total_weight <= 0.0:
		return enemy_scenes[0]
	var roll := random.randf_range(0.0, total_weight)
	for index: int in enemy_scenes.size():
		roll -= maxf(current_weights[index] if index < current_weights.size() else 1.0, 0.0)
		if roll <= 0.0:
			return enemy_scenes[index]
	return enemy_scenes.back()


func _find_spawn_position() -> Vector2:
	var viewport_half := get_viewport().get_visible_rect().size * 0.5 / camera.zoom
	var fallback := player.global_position + Vector2(viewport_half.x + spawn_margin, 0.0)
	for _attempt: int in 12:
		var edge := random.randi_range(0, 3)
		var candidate := player.global_position
		if edge < 2:
			candidate.x += (-1.0 if edge == 0 else 1.0) * (viewport_half.x + spawn_margin)
			candidate.y += random.randf_range(-viewport_half.y - spawn_margin, viewport_half.y + spawn_margin)
		else:
			candidate.y += (-1.0 if edge == 2 else 1.0) * (viewport_half.y + spawn_margin)
			candidate.x += random.randf_range(-viewport_half.x - spawn_margin, viewport_half.x + spawn_margin)
		candidate.x = clampf(candidate.x, arena_bounds.position.x + 32.0, arena_bounds.end.x - 32.0)
		candidate.y = clampf(candidate.y, arena_bounds.position.y + 32.0, arena_bounds.end.y - 32.0)
		var outside_view := absf(candidate.x - player.global_position.x) > viewport_half.x + 24.0 or absf(candidate.y - player.global_position.y) > viewport_half.y + 24.0
		if outside_view and candidate.distance_to(player.global_position) >= minimum_player_distance:
			return candidate
	fallback.x = clampf(fallback.x, arena_bounds.position.x + 32.0, arena_bounds.end.x - 32.0)
	fallback.y = clampf(fallback.y, arena_bounds.position.y + 32.0, arena_bounds.end.y - 32.0)
	return fallback


func _on_enemy_died(_enemy: BaseEnemy, experience_reward: int, death_position: Vector2) -> void:
	active_enemy_count = maxi(0, active_enemy_count - 1)
	active_count_changed.emit(active_enemy_count)
	enemy_defeated.emit(experience_reward, death_position)
