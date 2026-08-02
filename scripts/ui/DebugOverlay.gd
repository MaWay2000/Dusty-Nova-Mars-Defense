class_name DebugOverlay
extends Control

@export var enabled_by_default: bool = false

@onready var label: Label = $Panel/Label

var player: Player
var spawner: EnemySpawner
var wave_manager: WaveManager


func _ready() -> void:
	visible = enabled_by_default


func setup(target_player: Player, enemy_spawner: EnemySpawner, waves: WaveManager) -> void:
	player = target_player
	spawner = enemy_spawner
	wave_manager = waves


func _process(_delta: float) -> void:
	if not visible or not is_instance_valid(player):
		return
	label.text = "FPS  %d\nENEMIES  %d\nPROJECTILES  %d\nPLAYER  %.0f, %.0f\nWAVE  %d" % [
		Engine.get_frames_per_second(),
		spawner.active_enemy_count,
		get_tree().get_node_count_in_group("projectiles"),
		player.global_position.x,
		player.global_position.y,
		wave_manager.current_wave,
	]


func toggle() -> void:
	visible = not visible
