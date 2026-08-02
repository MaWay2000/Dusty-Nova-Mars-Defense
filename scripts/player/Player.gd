class_name Player
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal experience_changed(current: int, required: int)
signal level_changed(level: int)
signal leveled_up(level: int)
signal shield_changed(current: float, maximum: float)
signal nova_pulse_triggered(position: Vector2, radius: float)
signal damaged(amount: float)
signal died

@export_category("Movement")
@export var maximum_speed: float = 220.0
@export var acceleration: float = 1200.0
@export var deceleration: float = 1500.0
@export var boundary_padding: float = 24.0

@export_category("Health")
@export var maximum_health: float = 100.0
@export var damage_invulnerability: float = 0.5
@export var shield_recharge_delay: float = 5.0
@export var shield_recharge_rate: float = 5.0
@export var combat_repair_interval: float = 3.0

@export_category("Experience")
@export var starting_experience_required: int = 20
@export var experience_growth: float = 1.35

@export_category("Upgrade Systems")
@export var nova_pulse_interval: float = 8.0
@export var nova_pulse_radius: float = 320.0
@export var nova_pulse_damage_per_level: float = 25.0

@onready var input_controller: InputController = $InputController
@onready var weapon: Weapon = $Weapon
@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var current_health: float
var current_experience: int = 0
var current_level: int = 1
var experience_required: int
var experience_multiplier: float = 1.0
var experience_remainder: float = 0.0
var pickup_attraction_bonus: float = 0.0
var contact_damage_reduction: float = 0.0
var maximum_shield: float = 0.0
var current_shield: float = 0.0
var shield_recharge_remaining: float = 0.0
var combat_repair_amount: float = 0.0
var combat_repair_remaining: float = 3.0
var nova_pulse_level: int = 0
var nova_pulse_remaining: float = 8.0
var arena_bounds: Rect2
var invulnerability_remaining: float = 0.0
var is_dead: bool = false


func _ready() -> void:
	current_health = maximum_health
	experience_required = starting_experience_required
	health_changed.emit(current_health, maximum_health)
	shield_changed.emit(current_shield, maximum_shield)
	experience_changed.emit(current_experience, experience_required)
	level_changed.emit(current_level)


func setup(bounds: Rect2) -> void:
	arena_bounds = bounds


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	invulnerability_remaining = maxf(0.0, invulnerability_remaining - delta)
	_process_upgrade_systems(delta)
	var direction := input_controller.get_movement_direction()
	var target_velocity := direction * maximum_speed
	var rate := acceleration if direction.length_squared() > 0.0 else deceleration
	velocity = velocity.move_toward(target_velocity, rate * delta)
	move_and_slide()
	if arena_bounds.has_area():
		global_position.x = clampf(global_position.x, arena_bounds.position.x + boundary_padding, arena_bounds.end.x - boundary_padding)
		global_position.y = clampf(global_position.y, arena_bounds.position.y + boundary_padding, arena_bounds.end.y - boundary_padding)


func take_damage(amount: float) -> void:
	if is_dead or invulnerability_remaining > 0.0:
		return
	invulnerability_remaining = damage_invulnerability
	shield_recharge_remaining = shield_recharge_delay
	var remaining_damage := amount
	if current_shield > 0.0:
		var absorbed := minf(current_shield, remaining_damage)
		current_shield -= absorbed
		remaining_damage -= absorbed
		shield_changed.emit(current_shield, maximum_shield)
	if remaining_damage > 0.0:
		current_health = maxf(0.0, current_health - remaining_damage)
	health_changed.emit(current_health, maximum_health)
	damaged.emit(amount)
	_flash(Color(1.0, 0.35, 0.35))
	if current_health <= 0.0:
		_die()


func take_contact_damage(amount: float) -> void:
	take_damage(amount * maxf(0.0, 1.0 - contact_damage_reduction))


func heal(amount: float) -> void:
	if is_dead:
		return
	current_health = minf(maximum_health, current_health + amount)
	health_changed.emit(current_health, maximum_health)


func increase_maximum_health(amount: float) -> void:
	maximum_health += amount
	current_health = minf(maximum_health, current_health + amount)
	health_changed.emit(current_health, maximum_health)


func increase_maximum_shield(amount: float) -> void:
	maximum_shield += amount
	current_shield = minf(maximum_shield, current_shield + amount)
	shield_changed.emit(current_shield, maximum_shield)


func add_nova_pulse_level() -> void:
	nova_pulse_level += 1
	nova_pulse_remaining = minf(nova_pulse_remaining, nova_pulse_interval)


func add_combat_repair(amount: float) -> void:
	if combat_repair_amount <= 0.0:
		combat_repair_remaining = combat_repair_interval
	combat_repair_amount += amount


func add_experience(amount: int) -> void:
	if is_dead:
		return
	var adjusted_experience := amount * experience_multiplier + experience_remainder
	var whole_experience := floori(adjusted_experience)
	experience_remainder = adjusted_experience - whole_experience
	current_experience += whole_experience
	while current_experience >= experience_required:
		current_experience -= experience_required
		current_level += 1
		experience_required = int(round(starting_experience_required * pow(experience_growth, current_level - 1)))
		level_changed.emit(current_level)
		leveled_up.emit(current_level)
	experience_changed.emit(current_experience, experience_required)


func _process_upgrade_systems(delta: float) -> void:
	if shield_recharge_remaining > 0.0:
		shield_recharge_remaining = maxf(0.0, shield_recharge_remaining - delta)
	elif current_shield < maximum_shield:
		current_shield = minf(maximum_shield, current_shield + shield_recharge_rate * delta)
		shield_changed.emit(current_shield, maximum_shield)
	if combat_repair_amount > 0.0:
		combat_repair_remaining -= delta
		if combat_repair_remaining <= 0.0:
			combat_repair_remaining += combat_repair_interval
			heal(combat_repair_amount)
	if nova_pulse_level > 0:
		nova_pulse_remaining -= delta
		if nova_pulse_remaining <= 0.0:
			nova_pulse_remaining += nova_pulse_interval
			_trigger_nova_pulse()


func _trigger_nova_pulse() -> void:
	var damage_amount := nova_pulse_damage_per_level * nova_pulse_level
	var radius_squared := nova_pulse_radius * nova_pulse_radius
	for candidate: Node in get_tree().get_nodes_in_group("enemies"):
		if candidate is Node2D and is_instance_valid(candidate):
			var enemy := candidate as Node2D
			if global_position.distance_squared_to(enemy.global_position) <= radius_squared and enemy.has_method("take_damage"):
				enemy.take_damage(damage_amount)
	nova_pulse_triggered.emit(global_position, nova_pulse_radius)


func _flash(color: Color) -> void:
	visual.modulate = color
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.16)


func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	weapon.enabled = false
	collision_shape.set_deferred("disabled", true)
	visual.hide()
	died.emit()
