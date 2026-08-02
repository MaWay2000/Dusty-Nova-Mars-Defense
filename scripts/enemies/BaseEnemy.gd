class_name BaseEnemy
extends CharacterBody2D

signal died(enemy: BaseEnemy, experience_reward: int, death_position: Vector2)
signal hit

@export var maximum_health: float = 30.0
@export var movement_speed: float = 90.0
@export var contact_damage: float = 10.0
@export var experience_reward: int = 5

@onready var visual: Polygon2D = $Visual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var damage_area: Area2D = $DamageArea
@onready var damage_timer: Timer = $DamageTimer

var target_player: Player
var current_health: float
var contact_target: Player
var dead: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	current_health = maximum_health
	add_to_group("enemies")
	damage_area.body_entered.connect(_on_damage_area_body_entered)
	damage_area.body_exited.connect(_on_damage_area_body_exited)
	damage_timer.timeout.connect(_damage_contact_target)


func setup(player: Player) -> void:
	target_player = player


func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(target_player) or target_player.is_dead:
		velocity = Vector2.ZERO
		return
	velocity = global_position.direction_to(target_player.global_position) * movement_speed + knockback_velocity
	move_and_slide()
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 900.0 * delta)


func take_damage(amount: float) -> void:
	if dead:
		return
	current_health -= amount
	hit.emit()
	_flash()
	if current_health <= 0.0:
		_die()


func is_alive() -> bool:
	return not dead


func apply_knockback(direction: Vector2, strength: float) -> void:
	knockback_velocity += direction.normalized() * strength


func _on_damage_area_body_entered(body: Node2D) -> void:
	if body is Player:
		contact_target = body as Player
		_damage_contact_target()
		damage_timer.start()


func _on_damage_area_body_exited(body: Node2D) -> void:
	if body == contact_target:
		contact_target = null
		damage_timer.stop()


func _damage_contact_target() -> void:
	if not is_instance_valid(contact_target) or contact_target.is_dead:
		damage_timer.stop()
		return
	contact_target.take_contact_damage(contact_damage)


func _flash() -> void:
	visual.modulate = Color(1.0, 0.45, 0.35)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, 0.12)


func _die() -> void:
	dead = true
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	damage_area.set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	damage_timer.stop()
	died.emit(self, experience_reward, global_position)
	queue_free()
