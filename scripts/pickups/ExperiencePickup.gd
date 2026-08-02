class_name ExperiencePickup
extends Area2D

signal collected

@export var attraction_radius: float = 240.0
@export var attraction_speed: float = 420.0
@export var pickup_radius: float = 28.0

@onready var visual: Polygon2D = $Visual

var target_player: Player
var experience_value: int = 1
var is_collected: bool = false
var animation_time: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func setup(player: Player, value: int) -> void:
	target_player = player
	experience_value = value


func _physics_process(delta: float) -> void:
	animation_time += delta
	visual.rotation = animation_time * 2.5
	visual.scale = Vector2.ONE * (1.0 + sin(animation_time * 5.0) * 0.08)
	if is_collected or not is_instance_valid(target_player) or target_player.is_dead:
		return
	var distance := global_position.distance_to(target_player.global_position)
	if distance <= pickup_radius:
		_collect()
	elif distance <= attraction_radius + target_player.pickup_attraction_bonus:
		global_position = global_position.move_toward(target_player.global_position, attraction_speed * delta)


func _on_body_entered(body: Node2D) -> void:
	if body == target_player:
		_collect()


func _collect() -> void:
	if is_collected:
		return
	is_collected = true
	collected.emit()
	target_player.add_experience(experience_value)
	queue_free()
