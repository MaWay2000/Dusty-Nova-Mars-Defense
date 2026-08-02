extends SceneTree

class DamageDummy extends Node2D:
	var health: float = 1000.0
	var knockback_received: float = 0.0

	func take_damage(amount: float) -> void:
		health -= amount

	func apply_knockback(_direction: Vector2, strength: float) -> void:
		knockback_received += strength

	func is_alive() -> bool:
		return health > 0.0


var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		failures.append(message)
		push_error("FAIL: " + message)


func _find_upgrade(manager: UpgradeManager, upgrade_id: StringName) -> UpgradeData:
	for upgrade: UpgradeData in manager.upgrade_pool:
		if upgrade.upgrade_id == upgrade_id:
			return upgrade
	return null


func _choice_ids(choices: Array[UpgradeData]) -> Array[StringName]:
	var ids: Array[StringName] = []
	for upgrade: UpgradeData in choices:
		ids.append(upgrade.upgrade_id)
	return ids


func _contains_rarity(choices: Array[UpgradeData], rarity: int) -> bool:
	for upgrade: UpgradeData in choices:
		if upgrade.rarity == rarity:
			return true
	return false


func _run() -> void:
	var main_scene := load("res://scenes/main/Main.tscn") as PackedScene
	_check(main_scene != null, "main scene loads")
	if main_scene == null:
		quit(1)
		return

	var main := main_scene.instantiate()
	root.add_child(main)
	current_scene = main
	await process_frame
	await process_frame

	var player := main.get_node("Player") as Player
	var spawner := main.get_node("EnemySpawner") as EnemySpawner
	var waves := main.get_node("WaveManager") as WaveManager
	var upgrades := main.get_node("UpgradeManager") as UpgradeManager
	var upgrade_panel := main.get_node("GameplayUI/UpgradePanel") as UpgradePanel
	var pause_menu := main.get_node("GameplayUI/PauseMenu") as PauseMenu
	var end_screen := main.get_node("GameplayUI/EndScreen") as EndScreen
	_check(player != null and spawner != null and upgrades != null, "core gameplay nodes resolve")
	_check(main.get_node_or_null("GameplayUI/UpgradePanel") != null, "upgrade panel resolves")
	_check(main.get_node_or_null("GameplayUI/DebugOverlay") != null, "debug overlay resolves")

	var all_upgrade_ids := _choice_ids(upgrades.upgrade_pool)
	var unique_upgrade_ids := all_upgrade_ids.duplicate()
	var duplicate_check: Dictionary = {}
	for upgrade_id: StringName in unique_upgrade_ids:
		duplicate_check[upgrade_id] = true
	_check(upgrades.upgrade_pool.size() == 18 and duplicate_check.size() == 18, "the recommended 18-upgrade pool loads with unique IDs")
	_check(is_equal_approx(_find_upgrade(upgrades, &"damage").amount, 3.0), "Overcharged Cells uses the rebalanced +3 damage value")
	_check(is_equal_approx(_find_upgrade(upgrades, &"fire_rate").amount, 0.5), "Rapid Capacitor uses the rebalanced +0.5 fire-rate value")
	var level_two_pool := upgrades._get_available_upgrades(2)
	var level_two_ids := _choice_ids(level_two_pool)
	_check(&"heal" not in level_two_ids, "healing-only upgrades are hidden at full health")
	player.current_health -= 1.0
	_check(&"heal" in _choice_ids(upgrades._get_available_upgrades(2)), "healing-only upgrades return when health is missing")
	player.current_health = player.maximum_health
	upgrades.current_levels[&"damage"] = 8
	_check(&"damage" not in _choice_ids(upgrades._get_available_upgrades(10)), "maxed upgrades are removed from the pool")
	upgrades.current_levels[&"damage"] = 0
	_check(_contains_rarity(upgrades._select_choices(5), 1), "every fifth level guarantees a Rare choice")
	_check(_contains_rarity(upgrades._select_choices(10), 2), "every tenth level guarantees a Legendary choice")

	waves.phase_remaining = 0.01
	await create_timer(0.03).timeout
	_check(waves.in_intermission and not spawner.spawning_enabled, "wave transition pauses spawning for intermission")
	waves.phase_remaining = 0.01
	await create_timer(0.03).timeout
	_check(waves.current_wave == 2 and spawner.spawning_enabled and spawner.maximum_active_enemies == 45, "next wave increases difficulty and resumes spawning")

	var starting_position := player.global_position
	Input.action_press("move_right")
	await create_timer(0.3).timeout
	Input.action_release("move_right")
	_check(player.global_position.x > starting_position.x + 10.0, "keyboard input moves the player")

	var test_weights: Array[float] = [1.0, 0.0]
	spawner.configure_wave(0.05, 6, test_weights)
	await create_timer(0.45).timeout
	_check(spawner.active_enemy_count > 0 and spawner.active_enemy_count <= 6, "weighted spawner creates enemies within its cap")
	spawner.stop_spawning()
	waves.running = false
	for existing_enemy: Node in get_nodes_in_group("enemies"):
		existing_enemy.queue_free()
	await process_frame

	var crawler_scene := load("res://scenes/enemies/MarsCrawler.tscn") as PackedScene
	var crawler := crawler_scene.instantiate() as BaseEnemy
	Input.warp_mouse(Vector2(20.0, 20.0))
	await process_frame
	var mouse_aim := player.weapon.global_position.direction_to(player.weapon.get_global_mouse_position())
	_check(not mouse_aim.is_zero_approx(), "mouse position provides the weapon aim direction")
	main.add_child(crawler)
	crawler.global_position = player.global_position + mouse_aim * 160.0
	crawler.setup(player)
	await create_timer(1.4).timeout
	_check(not is_instance_valid(crawler), "automatic weapon fires toward the mouse and defeats an enemy in its path")

	var original_level := player.current_level
	player.add_experience(player.experience_required)
	await process_frame
	_check(paused and upgrades.is_selecting(), "level-up pauses play and opens upgrade selection")
	var first_choice_ids := _choice_ids(upgrades.current_choices)
	var first_choice_set: Dictionary = {}
	for upgrade_id: StringName in first_choice_ids:
		first_choice_set[upgrade_id] = true
	_check(upgrades.current_choices.size() == 3 and first_choice_set.size() == 3, "level-up presents three unique choices")
	_check(upgrade_panel.card_labels[0].text.contains("[font_size=32]") and upgrade_panel.card_labels[0].text.contains("[hr]"), "upgrade cards use large top-aligned names and solid divider lines")
	upgrades._on_reroll_requested()
	var rerolled_ids := _choice_ids(upgrades.current_choices)
	var rerolled_set: Dictionary = {}
	for upgrade_id: StringName in rerolled_ids:
		rerolled_set[upgrade_id] = true
	_check(upgrades.rerolls_remaining == 0 and rerolled_set.size() == 3, "one reroll replaces the offer with three unique choices")
	_check(first_choice_set.keys().all(func(id: Variant) -> bool: return id not in rerolled_ids), "reroll avoids the previous choices when enough upgrades are available")
	upgrades._on_choice_selected(0)
	await process_frame
	_check(not paused and player.current_level == original_level + 1, "choosing an upgrade applies it and resumes play")

	var lifetime_before := player.weapon.projectile_lifetime
	upgrades._apply_upgrade(_find_upgrade(upgrades, &"weapon_range"))
	_check(player.weapon.projectile_lifetime > lifetime_before, "Longshot Optics increases effective mouse-fired projectile range")
	var pickup_bonus_before := player.pickup_attraction_bonus
	upgrades._apply_upgrade(_find_upgrade(upgrades, &"pickup_range"))
	_check(player.pickup_attraction_bonus == pickup_bonus_before + 70.0, "Magnetic Collector increases pickup attraction range")
	var experience_multiplier_before := player.experience_multiplier
	upgrades._apply_upgrade(_find_upgrade(upgrades, &"experience_gain"))
	_check(is_equal_approx(player.experience_multiplier, experience_multiplier_before + 0.12), "Learning Protocol increases experience gain")
	var repair_before := player.combat_repair_amount
	upgrades._apply_upgrade(_find_upgrade(upgrades, &"combat_repair"))
	player.current_health = player.maximum_health - 5.0
	player._process_upgrade_systems(3.1)
	_check(player.combat_repair_amount == repair_before + 1.0 and player.current_health > player.maximum_health - 5.0, "Combat Repair restores health on its interval")
	var size_before := player.weapon.projectile_size_bonus
	var knockback_before := player.weapon.knockback_bonus
	upgrades._apply_upgrade(_find_upgrade(upgrades, &"heavy_rounds"))
	_check(player.weapon.projectile_size_bonus > size_before and player.weapon.knockback_bonus > knockback_before, "Heavy Rounds increases projectile size and knockback")
	var pierce_before := player.weapon.pierce_count
	upgrades._apply_upgrade(_find_upgrade(upgrades, &"piercing"))
	_check(player.weapon.pierce_count == pierce_before + 1, "Piercing Core adds one penetration")
	var split_before := player.weapon.split_lens_level
	upgrades._apply_upgrade(_find_upgrade(upgrades, &"split_shot"))
	_check(player.weapon.split_lens_level == split_before + 1, "Split Lens adds a pair of side projectiles")
	var critical_before := player.weapon.critical_chance
	upgrades._apply_upgrade(_find_upgrade(upgrades, &"critical"))
	_check(is_equal_approx(player.weapon.critical_chance, critical_before + 0.1), "Critical Circuit adds critical-hit chance")
	var splash_before := player.weapon.splash_damage_ratio
	upgrades._apply_upgrade(_find_upgrade(upgrades, &"explosive"))
	_check(is_equal_approx(player.weapon.splash_damage_ratio, splash_before + 0.25), "Explosive Cells adds splash damage")
	var reduction_before := player.contact_damage_reduction
	upgrades._apply_upgrade(_find_upgrade(upgrades, &"contact_reduction"))
	_check(is_equal_approx(player.contact_damage_reduction, reduction_before + 0.07), "Reactive Plating reduces contact damage")
	upgrades._apply_upgrade(_find_upgrade(upgrades, &"shield"))
	var health_before_shield_hit := player.current_health
	player.invulnerability_remaining = 0.0
	player.take_damage(10.0)
	_check(player.maximum_shield >= 25.0 and player.current_health == health_before_shield_hit, "Shield Generator absorbs damage before health")
	player.weapon.enabled = false
	var projectile_ids_before: Dictionary = {}
	for existing_projectile: Node in get_nodes_in_group("projectiles"):
		projectile_ids_before[existing_projectile.get_instance_id()] = true
	player.weapon._shoot(Vector2.RIGHT)
	var volley: Array[Projectile] = []
	for spawned_projectile: Node in get_nodes_in_group("projectiles"):
		if not projectile_ids_before.has(spawned_projectile.get_instance_id()):
			volley.append(spawned_projectile as Projectile)
	_check(volley.size() == 1 + player.weapon.split_lens_level * 2, "Split Lens creates the expected side-projectile pair")
	_check(not volley.is_empty() and volley[0].remaining_pierces == player.weapon.pierce_count and is_equal_approx(volley[0].scale.x, 1.0 + player.weapon.projectile_size_bonus), "weapon upgrades configure spawned projectiles")
	for volley_projectile: Projectile in volley:
		volley_projectile.queue_free()
	await process_frame

	var projectile_scene := load("res://scenes/projectiles/EnergyProjectile.tscn") as PackedScene
	var piercing_projectile := projectile_scene.instantiate() as Projectile
	main.add_child(piercing_projectile)
	piercing_projectile.setup(Vector2.RIGHT, 100.0, 700.0, 1.4, 1.2, 0.15, 1, 0.0, 82.0)
	var first_dummy := DamageDummy.new()
	var second_dummy := DamageDummy.new()
	main.add_child(first_dummy)
	main.add_child(second_dummy)
	piercing_projectile._on_body_entered(first_dummy)
	piercing_projectile._on_body_entered(second_dummy)
	_check(first_dummy.health == 900.0 and second_dummy.health == 925.0 and piercing_projectile.is_queued_for_deletion(), "piercing damages a second target at 75% damage")
	_check(first_dummy.knockback_received > 0.0, "heavy projectile knockback reaches enemies")
	first_dummy.queue_free()
	second_dummy.queue_free()

	var explosive_projectile := projectile_scene.instantiate() as Projectile
	main.add_child(explosive_projectile)
	explosive_projectile.setup(Vector2.RIGHT, 100.0, 700.0, 1.4, 1.0, 0.0, 0, 0.25, 82.0)
	var direct_dummy := DamageDummy.new()
	var splash_dummy := DamageDummy.new()
	main.add_child(direct_dummy)
	main.add_child(splash_dummy)
	direct_dummy.add_to_group("enemies")
	splash_dummy.add_to_group("enemies")
	direct_dummy.global_position = Vector2.ZERO
	splash_dummy.global_position = Vector2(40.0, 0.0)
	explosive_projectile.global_position = Vector2.ZERO
	explosive_projectile._on_body_entered(direct_dummy)
	_check(direct_dummy.health == 900.0 and splash_dummy.health == 975.0, "explosive projectiles apply 25% splash damage")
	direct_dummy.queue_free()
	splash_dummy.queue_free()

	player.current_shield = 0.0
	player.invulnerability_remaining = 0.0
	player.current_health = player.maximum_health
	player.take_contact_damage(10.0)
	_check(is_equal_approx(player.current_health, player.maximum_health - 10.0 * (1.0 - player.contact_damage_reduction)), "contact damage uses Reactive Plating reduction")
	player.heal(1000.0)
	var nova_target := crawler_scene.instantiate() as BaseEnemy
	main.add_child(nova_target)
	nova_target.global_position = player.global_position + Vector2(100.0, 0.0)
	nova_target.setup(player)
	nova_target.set_physics_process(false)
	upgrades._apply_upgrade(_find_upgrade(upgrades, &"nova_pulse"))
	player._trigger_nova_pulse()
	_check(is_equal_approx(nova_target.current_health, nova_target.maximum_health - 25.0), "Nova Pulse damages nearby enemies")
	nova_target.queue_free()

	main._toggle_pause()
	_check(paused and pause_menu.visible, "pause menu stops gameplay")
	main._resume_game()
	_check(not paused and not pause_menu.visible, "resume closes the pause menu")

	player.invulnerability_remaining = 0.0
	player.take_damage(10000.0)
	await process_frame
	_check(paused and end_screen.visible, "player death opens the mission-failed screen")

	paused = false
	main.queue_free()
	await process_frame
	var victory_main := main_scene.instantiate()
	root.add_child(victory_main)
	current_scene = victory_main
	await process_frame
	victory_main._on_round_completed()
	await process_frame
	var victory_screen := victory_main.get_node("GameplayUI/EndScreen") as EndScreen
	_check(paused and victory_screen.visible, "round completion opens the victory screen")

	paused = false
	victory_main.queue_free()
	await process_frame
	if failures.is_empty():
		print("SMOKE TEST PASSED")
		quit(0)
	else:
		print("SMOKE TEST FAILED: ", failures)
		quit(1)
