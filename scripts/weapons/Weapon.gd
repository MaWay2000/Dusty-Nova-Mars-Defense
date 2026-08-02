class_name Weapon
extends Node2D

signal shot_fired

@export var projectile_scene: PackedScene
@export var damage: float = 15.0
@export var fire_rate: float = 3.0
@export var attack_range: float = 450.0
@export var projectile_speed: float = 700.0
@export var projectile_lifetime: float = 1.4

var projectile_size_bonus: float = 0.0
var knockback_bonus: float = 0.0
var pierce_count: int = 0
var split_lens_level: int = 0
var critical_chance: float = 0.0
var critical_multiplier: float = 2.0
var splash_damage_ratio: float = 0.0
var splash_radius: float = 82.0

@onready var barrel: Node2D = $Barrel
@onready var muzzle: Marker2D = $Barrel/Muzzle

var enabled: bool = true
var cooldown: float = 0.0


func _physics_process(delta: float) -> void:
	if not enabled or projectile_scene == null:
		return
	var mouse_position := get_global_mouse_position()
	barrel.look_at(mouse_position)
	cooldown -= delta
	if cooldown > 0.0:
		return
	var aim_direction := global_position.direction_to(mouse_position)
	if aim_direction.is_zero_approx():
		return
	_shoot(aim_direction)
	cooldown = 1.0 / maxf(fire_rate, 0.1)


func _shoot(direction: Vector2) -> void:
	_spawn_projectile(direction, 1.0)
	for split_level: int in split_lens_level:
		var angle_offset := deg_to_rad(10.0 * (split_level + 1))
		_spawn_projectile(direction.rotated(-angle_offset), 0.35)
		_spawn_projectile(direction.rotated(angle_offset), 0.35)
	shot_fired.emit()


func _spawn_projectile(direction: Vector2, damage_multiplier: float) -> void:
	var projectile := projectile_scene.instantiate() as Projectile
	if projectile == null:
		return
	var projectile_damage := damage * damage_multiplier
	if randf() < critical_chance:
		projectile_damage *= critical_multiplier
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = muzzle.global_position
	projectile.setup(
		direction,
		projectile_damage,
		projectile_speed,
		projectile_lifetime,
		1.0 + projectile_size_bonus,
		knockback_bonus,
		pierce_count,
		splash_damage_ratio,
		splash_radius
	)
