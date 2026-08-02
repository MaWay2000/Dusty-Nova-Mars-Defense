class_name WaveManager
extends Node

signal wave_changed(wave: int, total_waves: int, is_intermission: bool, configuration: Dictionary)
signal time_updated(time_remaining: float)
signal round_completed

@export var wave_duration: float = 70.0
@export var intermission_duration: float = 5.0
@export var spawn_intervals: Array[float] = [1.30, 0.90, 0.65, 0.45]
@export var enemy_limits: Array[int] = [30, 45, 60, 80]
@export var crawler_weights: Array[float] = [1.0, 0.8, 0.55, 0.4]
@export var runner_weights: Array[float] = [0.0, 0.2, 0.45, 0.6]

var current_wave: int = 0
var phase_remaining: float = 0.0
var total_remaining: float = 0.0
var running: bool = false
var in_intermission: bool = false


func start_round() -> void:
	if spawn_intervals.is_empty():
		push_error("WaveManager requires at least one wave configuration.")
		return
	current_wave = 1
	phase_remaining = wave_duration
	total_remaining = get_total_round_duration()
	running = true
	in_intermission = false
	_emit_current_wave()
	time_updated.emit(total_remaining)


func _process(delta: float) -> void:
	if not running:
		return
	phase_remaining -= delta
	total_remaining = maxf(0.0, total_remaining - delta)
	time_updated.emit(total_remaining)
	if phase_remaining > 0.0:
		return
	if in_intermission:
		current_wave += 1
		in_intermission = false
		phase_remaining = wave_duration
		_emit_current_wave()
	elif current_wave < spawn_intervals.size():
		in_intermission = true
		phase_remaining = intermission_duration
		wave_changed.emit(current_wave, spawn_intervals.size(), true, {})
	else:
		running = false
		round_completed.emit()


func get_total_round_duration() -> float:
	return wave_duration * spawn_intervals.size() + intermission_duration * maxi(0, spawn_intervals.size() - 1)


func get_elapsed_time() -> float:
	return get_total_round_duration() - total_remaining


func _emit_current_wave() -> void:
	var index := current_wave - 1
	var configuration := {
		"spawn_interval": spawn_intervals[index],
		"enemy_limit": enemy_limits[index] if index < enemy_limits.size() else enemy_limits.back(),
		"weights": [
			crawler_weights[index] if index < crawler_weights.size() else crawler_weights.back(),
			runner_weights[index] if index < runner_weights.size() else runner_weights.back()
		]
	}
	wave_changed.emit(current_wave, spawn_intervals.size(), false, configuration)
