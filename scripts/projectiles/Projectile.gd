class_name Projectile
extends Area2D

@export var lifetime: float = 1.4
@export var impact_scene: PackedScene

var direction: Vector2 = Vector2.RIGHT
var damage: float = 15.0
var speed: float = 700.0
var remaining_lifetime: float
var knockback_bonus: float = 0.0
var remaining_pierces: int = 0
var splash_damage_ratio: float = 0.0
var splash_radius: float = 82.0
var hit_instance_ids: Dictionary = {}


func _ready() -> void:
	remaining_lifetime = lifetime
	body_entered.connect(_on_body_entered)


func setup(
	new_direction: Vector2,
	new_damage: float,
	new_speed: float,
	new_lifetime: float = 1.4,
	new_scale: float = 1.0,
	new_knockback_bonus: float = 0.0,
	new_pierces: int = 0,
	new_splash_damage_ratio: float = 0.0,
	new_splash_radius: float = 82.0
) -> void:
	direction = new_direction.normalized()
	damage = new_damage
	speed = new_speed
	lifetime = new_lifetime
	remaining_lifetime = lifetime
	scale = Vector2.ONE * new_scale
	knockback_bonus = new_knockback_bonus
	remaining_pierces = new_pierces
	splash_damage_ratio = new_splash_damage_ratio
	splash_radius = new_splash_radius
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	remaining_lifetime -= delta
	if remaining_lifetime <= 0.0:
		queue_free()


func _on_body_entered(body: Node2D) -> void:
	var instance_id := body.get_instance_id()
	if hit_instance_ids.has(instance_id) or not body.has_method("take_damage"):
		return
	hit_instance_ids[instance_id] = true
	body.take_damage(damage)
	if knockback_bonus > 0.0 and body.has_method("apply_knockback"):
		body.apply_knockback(direction, 600.0 * knockback_bonus)
	_apply_splash_damage(body)
	_spawn_impact()
	if remaining_pierces > 0:
		remaining_pierces -= 1
		damage *= 0.75
	else:
		queue_free()


func _apply_splash_damage(direct_target: Node2D) -> void:
	if splash_damage_ratio <= 0.0:
		return
	var radius_squared := splash_radius * splash_radius
	for candidate: Node in get_tree().get_nodes_in_group("enemies"):
		if not candidate is Node2D or candidate == direct_target or not is_instance_valid(candidate):
			continue
		var enemy := candidate as Node2D
		if hit_instance_ids.has(enemy.get_instance_id()):
			continue
		if global_position.distance_squared_to(enemy.global_position) <= radius_squared and enemy.has_method("take_damage"):
			enemy.take_damage(damage * splash_damage_ratio)


func _spawn_impact() -> void:
	if impact_scene == null:
		return
	var impact := impact_scene.instantiate() as Node2D
	get_tree().current_scene.add_child(impact)
	impact.global_position = global_position
