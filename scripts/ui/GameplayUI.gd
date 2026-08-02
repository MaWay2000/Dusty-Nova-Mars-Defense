class_name GameplayUI
extends CanvasLayer

signal pause_pressed

@onready var health_bar: ProgressBar = $HUD/Margin/Root/TopRow/HealthBlock/HealthLayout/HealthBar
@onready var health_label: Label = $HUD/Margin/Root/TopRow/HealthBlock/HealthLayout/HealthLabel
@onready var wave_label: Label = $HUD/Margin/Root/TopRow/WaveBlock/WaveLayout/WaveLabel
@onready var timer_label: Label = $HUD/Margin/Root/TopRow/WaveBlock/WaveLayout/TimerLabel
@onready var enemy_label: Label = $HUD/Margin/Root/TopRow/StatsBlock/StatsLayout/Labels/EnemyLabel
@onready var score_label: Label = $HUD/Margin/Root/TopRow/StatsBlock/StatsLayout/Labels/ScoreLabel
@onready var level_label: Label = $HUD/Margin/Root/BottomRow/LevelLabel
@onready var experience_bar: ProgressBar = $HUD/Margin/Root/BottomRow/ExperienceBar
@onready var pause_button: Button = $HUD/Margin/Root/TopRow/StatsBlock/StatsLayout/PauseButton

var target_health: float = 100.0
var target_experience: float = 0.0
var displayed_health: float = 100.0
var displayed_maximum_health: float = 100.0
var displayed_shield: float = 0.0
var displayed_maximum_shield: float = 0.0


func _ready() -> void:
	pause_button.pressed.connect(func() -> void: pause_pressed.emit())


func _process(delta: float) -> void:
	health_bar.value = move_toward(health_bar.value, target_health, 180.0 * delta)
	experience_bar.value = move_toward(experience_bar.value, target_experience, 220.0 * delta)


func set_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	target_health = current
	displayed_health = current
	displayed_maximum_health = maximum
	_refresh_health_label()


func set_shield(current: float, maximum: float) -> void:
	displayed_shield = current
	displayed_maximum_shield = maximum
	_refresh_health_label()


func _refresh_health_label() -> void:
	if displayed_maximum_shield > 0.0:
		health_label.text = "SHIELD %d/%d   SUIT %d/%d" % [ceili(displayed_shield), ceili(displayed_maximum_shield), ceili(displayed_health), ceili(displayed_maximum_health)]
	else:
		health_label.text = "SUIT  %d / %d" % [ceili(displayed_health), ceili(displayed_maximum_health)]


func set_experience(current: int, required: int) -> void:
	experience_bar.max_value = required
	target_experience = current


func set_level(level: int) -> void:
	level_label.text = "LEVEL %d" % level


func set_wave(wave: int, total: int, is_intermission: bool) -> void:
	wave_label.text = "INTERMISSION" if is_intermission else "WAVE %d / %d" % [wave, total]


func set_time(seconds: float) -> void:
	var total_seconds := maxi(0, ceili(seconds))
	timer_label.text = "%02d:%02d" % [total_seconds / 60, total_seconds % 60]


func set_enemy_count(count: int) -> void:
	enemy_label.text = "HOSTILES  %d" % count


func set_score(defeated: int) -> void:
	score_label.text = "DEFEATED  %d" % defeated
