extends Node2D

const EXPERIENCE_PICKUP_SCENE := preload("res://scenes/pickups/ExperiencePickup.tscn")
const DEATH_EFFECT_SCENE := preload("res://scenes/effects/EnemyDeathEffect.tscn")
const NOVA_PULSE_EFFECT_SCENE := preload("res://scenes/effects/NovaPulseEffect.tscn")

@onready var arena: MarsArena = $Arena
@onready var player: Player = $Player
@onready var camera: FollowCamera = $Player/Camera2D
@onready var enemy_spawner: EnemySpawner = $EnemySpawner
@onready var wave_manager: WaveManager = $WaveManager
@onready var upgrade_manager: UpgradeManager = $UpgradeManager
@onready var gameplay_ui: GameplayUI = $GameplayUI
@onready var upgrade_panel: UpgradePanel = $GameplayUI/UpgradePanel
@onready var pause_menu: PauseMenu = $GameplayUI/PauseMenu
@onready var end_screen: EndScreen = $GameplayUI/EndScreen
@onready var debug_overlay: DebugOverlay = $GameplayUI/DebugOverlay
@onready var audio_hooks: AudioHooks = $AudioHooks

var defeated_enemies: int = 0
var survival_time: float = 0.0
var round_ended: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bounds := arena.get_bounds()
	player.setup(bounds)
	camera.configure(bounds)
	enemy_spawner.setup(player, camera, bounds)
	upgrade_manager.setup(player, upgrade_panel)
	debug_overlay.setup(player, enemy_spawner, wave_manager)

	player.health_changed.connect(gameplay_ui.set_health)
	player.experience_changed.connect(gameplay_ui.set_experience)
	player.level_changed.connect(gameplay_ui.set_level)
	player.shield_changed.connect(gameplay_ui.set_shield)
	player.leveled_up.connect(upgrade_manager.request_upgrade)
	player.nova_pulse_triggered.connect(_on_nova_pulse_triggered)
	player.damaged.connect(_on_player_damaged)
	player.died.connect(_on_player_died)
	player.weapon.shot_fired.connect(func() -> void: audio_hooks.play(&"shoot"))

	enemy_spawner.enemy_defeated.connect(_on_enemy_defeated)
	enemy_spawner.enemy_hit.connect(func() -> void: audio_hooks.play(&"enemy_hit"))
	enemy_spawner.active_count_changed.connect(gameplay_ui.set_enemy_count)
	wave_manager.wave_changed.connect(_on_wave_changed)
	wave_manager.time_updated.connect(_on_time_updated)
	wave_manager.round_completed.connect(_on_round_completed)
	upgrade_manager.upgrade_applied.connect(func(_upgrade: UpgradeData) -> void: audio_hooks.play(&"level_up"))

	gameplay_ui.pause_pressed.connect(_toggle_pause)
	pause_menu.resume_requested.connect(_resume_game)
	pause_menu.restart_requested.connect(_restart_game)
	pause_menu.menu_requested.connect(pause_menu.show_main_menu_placeholder)
	pause_menu.quit_requested.connect(get_tree().quit)
	end_screen.restart_requested.connect(_restart_game)

	gameplay_ui.set_health(player.current_health, player.maximum_health)
	gameplay_ui.set_experience(player.current_experience, player.experience_required)
	gameplay_ui.set_level(player.current_level)
	gameplay_ui.set_shield(player.current_shield, player.maximum_shield)
	gameplay_ui.set_enemy_count(0)
	gameplay_ui.set_score(0)
	wave_manager.start_round()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_game"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		debug_overlay.toggle()
		get_viewport().set_input_as_handled()


func _toggle_pause() -> void:
	if round_ended or upgrade_manager.is_selecting():
		return
	if get_tree().paused:
		_resume_game()
	else:
		get_tree().paused = true
		pause_menu.open()


func _resume_game() -> void:
	if round_ended:
		return
	pause_menu.close()
	get_tree().paused = false


func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_wave_changed(wave: int, total: int, is_intermission: bool, configuration: Dictionary) -> void:
	gameplay_ui.set_wave(wave, total, is_intermission)
	if is_intermission:
		enemy_spawner.pause_spawning()
		return
	var weights: Array[float] = []
	for weight: Variant in configuration["weights"]:
		weights.append(float(weight))
	enemy_spawner.configure_wave(float(configuration["spawn_interval"]), int(configuration["enemy_limit"]), weights)


func _on_time_updated(time_remaining: float) -> void:
	survival_time = wave_manager.get_elapsed_time()
	gameplay_ui.set_time(time_remaining)


func _on_enemy_defeated(experience_reward: int, death_position: Vector2) -> void:
	defeated_enemies += 1
	gameplay_ui.set_score(defeated_enemies)
	var pickup := EXPERIENCE_PICKUP_SCENE.instantiate() as ExperiencePickup
	add_child(pickup)
	pickup.global_position = death_position
	pickup.setup(player, experience_reward)
	pickup.collected.connect(func() -> void: audio_hooks.play(&"experience_collect"))
	var effect := DEATH_EFFECT_SCENE.instantiate() as Node2D
	add_child(effect)
	effect.global_position = death_position
	audio_hooks.play(&"enemy_death")


func _on_player_damaged(_amount: float) -> void:
	camera.shake(8.0)
	audio_hooks.play(&"player_damage")


func _on_nova_pulse_triggered(pulse_position: Vector2, radius: float) -> void:
	var effect := NOVA_PULSE_EFFECT_SCENE.instantiate() as Node2D
	effect.call("setup", radius)
	add_child(effect)
	effect.global_position = pulse_position


func _on_player_died() -> void:
	if round_ended:
		return
	round_ended = true
	enemy_spawner.stop_spawning()
	get_tree().paused = true
	end_screen.show_result(false, survival_time, defeated_enemies, player.current_level)
	audio_hooks.play(&"game_over")


func _on_round_completed() -> void:
	if round_ended:
		return
	round_ended = true
	enemy_spawner.stop_spawning()
	get_tree().paused = true
	end_screen.show_result(true, wave_manager.get_total_round_duration(), defeated_enemies, player.current_level)
	audio_hooks.play(&"victory")
