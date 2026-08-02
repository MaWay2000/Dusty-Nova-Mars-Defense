class_name UpgradeManager
extends Node

signal upgrade_applied(upgrade: UpgradeData)

const UPGRADE_PATHS: Array[String] = [
	"res://data/upgrades/damage.tres",
	"res://data/upgrades/fire_rate.tres",
	"res://data/upgrades/movement_speed.tres",
	"res://data/upgrades/max_health.tres",
	"res://data/upgrades/heal.tres",
	"res://data/upgrades/projectile_speed.tres",
	"res://data/upgrades/weapon_range.tres",
	"res://data/upgrades/pickup_range.tres",
	"res://data/upgrades/experience_gain.tres",
	"res://data/upgrades/contact_reduction.tres",
	"res://data/upgrades/combat_repair.tres",
	"res://data/upgrades/heavy_rounds.tres",
	"res://data/upgrades/piercing.tres",
	"res://data/upgrades/split_shot.tres",
	"res://data/upgrades/critical.tres",
	"res://data/upgrades/explosive.tres",
	"res://data/upgrades/shield.tres",
	"res://data/upgrades/nova_pulse.tres",
]

var player: Player
var panel: UpgradePanel
var upgrade_pool: Array[UpgradeData] = []
var current_choices: Array[UpgradeData] = []
var current_levels: Dictionary = {}
var pending_levels: Array[int] = []
var current_offer_level: int = 2
var rerolls_remaining: int = 1
var selecting: bool = false


func _ready() -> void:
	for path: String in UPGRADE_PATHS:
		var upgrade := load(path) as UpgradeData
		if upgrade != null:
			upgrade_pool.append(upgrade)
			current_levels[upgrade.upgrade_id] = 0


func setup(target_player: Player, upgrade_panel: UpgradePanel) -> void:
	player = target_player
	panel = upgrade_panel
	panel.choice_selected.connect(_on_choice_selected)
	panel.reroll_requested.connect(_on_reroll_requested)


func request_upgrade(new_level: int) -> void:
	pending_levels.append(new_level)
	if not selecting:
		_present_next_level()


func is_selecting() -> bool:
	return selecting


func get_upgrade_level(upgrade_id: StringName) -> int:
	return int(current_levels.get(upgrade_id, 0))


func _present_next_level() -> void:
	if pending_levels.is_empty():
		get_tree().paused = false
		return
	selecting = true
	current_offer_level = pending_levels.pop_front()
	get_tree().paused = true
	current_choices = _select_choices(current_offer_level)
	if current_choices.size() < 3:
		push_error("UpgradeManager could not build three valid choices.")
		return
	_show_current_choices()


func _select_choices(player_level: int, excluded_ids: Array[StringName] = []) -> Array[UpgradeData]:
	var available := _get_available_upgrades(player_level, excluded_ids)
	if available.size() < 3 and not excluded_ids.is_empty():
		available = _get_available_upgrades(player_level)
	var selected: Array[UpgradeData] = []
	var guaranteed_rarity := -1
	if player_level % 10 == 0:
		guaranteed_rarity = 2
	elif player_level % 5 == 0:
		guaranteed_rarity = 1
	if guaranteed_rarity >= 0:
		var guaranteed := _pick_from_rarity(available, guaranteed_rarity)
		if guaranteed != null:
			selected.append(guaranteed)
			available.erase(guaranteed)
	while selected.size() < 3 and not available.is_empty():
		var choice := _pick_weighted(available)
		if choice == null:
			break
		selected.append(choice)
		available.erase(choice)
	return selected


func _get_available_upgrades(player_level: int, excluded_ids: Array[StringName] = []) -> Array[UpgradeData]:
	var available: Array[UpgradeData] = []
	for upgrade: UpgradeData in upgrade_pool:
		if upgrade.upgrade_id in excluded_ids or player_level < upgrade.unlock_level:
			continue
		var current_level := get_upgrade_level(upgrade.upgrade_id)
		if upgrade.max_level > 0 and current_level >= upgrade.max_level:
			continue
		if upgrade.healing_only and player.current_health >= player.maximum_health:
			continue
		available.append(upgrade)
	return available


func _pick_weighted(available: Array[UpgradeData]) -> UpgradeData:
	var roll := randf()
	var desired_rarity := 0
	if roll >= 0.93:
		desired_rarity = 2
	elif roll >= 0.65:
		desired_rarity = 1
	var choice := _pick_from_rarity(available, desired_rarity)
	if choice != null:
		return choice
	return available.pick_random() if not available.is_empty() else null


func _pick_from_rarity(available: Array[UpgradeData], rarity: int) -> UpgradeData:
	var matching: Array[UpgradeData] = []
	for upgrade: UpgradeData in available:
		if upgrade.rarity == rarity:
			matching.append(upgrade)
	return matching.pick_random() if not matching.is_empty() else null


func _on_reroll_requested() -> void:
	if not selecting or rerolls_remaining <= 0:
		return
	var previous_ids: Array[StringName] = []
	for upgrade: UpgradeData in current_choices:
		previous_ids.append(upgrade.upgrade_id)
	rerolls_remaining -= 1
	current_choices = _select_choices(current_offer_level, previous_ids)
	_show_current_choices()


func _on_choice_selected(index: int) -> void:
	if not selecting or index < 0 or index >= current_choices.size():
		return
	var upgrade := current_choices[index]
	_apply_upgrade(upgrade)
	current_levels[upgrade.upgrade_id] = get_upgrade_level(upgrade.upgrade_id) + 1
	upgrade_applied.emit(upgrade)
	panel.hide_choices()
	selecting = false
	if pending_levels.is_empty():
		get_tree().paused = false
	else:
		_present_next_level()


func _apply_upgrade(upgrade: UpgradeData) -> void:
	match upgrade.upgrade_id:
		&"damage":
			player.weapon.damage += upgrade.amount
		&"fire_rate":
			player.weapon.fire_rate += upgrade.amount
		&"movement_speed":
			player.maximum_speed += upgrade.amount
		&"max_health":
			player.increase_maximum_health(upgrade.amount)
		&"heal":
			player.heal(upgrade.amount)
		&"projectile_speed":
			player.weapon.projectile_speed += upgrade.amount
			player.weapon.projectile_lifetime += upgrade.secondary_value
		&"weapon_range":
			player.weapon.attack_range += upgrade.amount
			player.weapon.projectile_lifetime += upgrade.amount / maxf(player.weapon.projectile_speed, 1.0)
		&"pickup_range":
			player.pickup_attraction_bonus += upgrade.amount
		&"experience_gain":
			player.experience_multiplier += upgrade.amount
		&"contact_reduction":
			player.contact_damage_reduction = minf(0.9, player.contact_damage_reduction + upgrade.amount)
		&"combat_repair":
			player.add_combat_repair(upgrade.amount)
		&"heavy_rounds":
			player.weapon.projectile_size_bonus += upgrade.amount
			player.weapon.knockback_bonus += upgrade.secondary_value
		&"piercing":
			player.weapon.pierce_count += int(upgrade.amount)
		&"split_shot":
			player.weapon.split_lens_level += 1
		&"critical":
			player.weapon.critical_chance = minf(1.0, player.weapon.critical_chance + upgrade.amount)
		&"explosive":
			player.weapon.splash_damage_ratio += upgrade.amount
			player.weapon.splash_radius += 10.0
		&"shield":
			player.increase_maximum_shield(upgrade.amount)
		&"nova_pulse":
			player.add_nova_pulse_level()


func _show_current_choices() -> void:
	var previews: Array[String] = []
	var bonuses: Array[String] = []
	for upgrade: UpgradeData in current_choices:
		previews.append(_get_value_preview(upgrade))
		bonuses.append(_get_bonus_text(upgrade))
	panel.show_choices(current_choices, current_levels, rerolls_remaining, bonuses, previews)


func _get_bonus_text(upgrade: UpgradeData) -> String:
	match upgrade.upgrade_id:
		&"damage":
			return "+3 damage"
		&"fire_rate":
			return "+0.5 shots/sec"
		&"movement_speed":
			return "+18 move speed"
		&"max_health":
			return "+15 max health | Heal 15"
		&"heal":
			return "Heal 35"
		&"projectile_speed":
			return "+120 projectile speed\n+0.1 sec lifetime"
		&"weapon_range":
			return "+70 projectile range"
		&"pickup_range":
			return "+70 pickup range"
		&"experience_gain":
			return "+12% XP gained"
		&"contact_reduction":
			return "-7% contact damage"
		&"combat_repair":
			return "+1 health / 3 sec"
		&"heavy_rounds":
			return "+20% projectile size\n+15% knockback"
		&"piercing":
			return "+1 enemy pierced\nLater hits: 75% damage"
		&"split_shot":
			return "+2 side shots\n35% damage each"
		&"critical":
			return "+10% critical chance\nCritical hit: 2x damage"
		&"explosive":
			return "+25% splash damage"
		&"shield":
			return "+25 rechargeable shield"
		&"nova_pulse":
			return "Area blast every 8 sec"
	return upgrade.description


func _get_value_preview(upgrade: UpgradeData) -> String:
	match upgrade.upgrade_id:
		&"damage":
			return "%.0f > %.0f damage" % [player.weapon.damage, player.weapon.damage + upgrade.amount]
		&"fire_rate":
			return "%.1f > %.1f shots/sec" % [player.weapon.fire_rate, player.weapon.fire_rate + upgrade.amount]
		&"movement_speed":
			return "%.0f > %.0f move speed" % [player.maximum_speed, player.maximum_speed + upgrade.amount]
		&"max_health":
			return "%.0f > %.0f max health" % [player.maximum_health, player.maximum_health + upgrade.amount]
		&"heal":
			return "%.0f > %.0f health" % [player.current_health, minf(player.maximum_health, player.current_health + upgrade.amount)]
		&"projectile_speed":
			return "%.0f > %.0f projectile speed\n%.1f > %.1f sec lifetime" % [player.weapon.projectile_speed, player.weapon.projectile_speed + upgrade.amount, player.weapon.projectile_lifetime, player.weapon.projectile_lifetime + upgrade.secondary_value]
		&"weapon_range":
			var effective_range := player.weapon.projectile_speed * player.weapon.projectile_lifetime
			return "%.0f > %.0f px range" % [effective_range, effective_range + upgrade.amount]
		&"pickup_range":
			return "%.0f > %.0f px pickup range" % [240.0 + player.pickup_attraction_bonus, 240.0 + player.pickup_attraction_bonus + upgrade.amount]
		&"experience_gain":
			return "+%.0f%% > +%.0f%% XP" % [(player.experience_multiplier - 1.0) * 100.0, (player.experience_multiplier - 1.0 + upgrade.amount) * 100.0]
		&"contact_reduction":
			return "%.0f%% > %.0f%% damage reduction" % [player.contact_damage_reduction * 100.0, (player.contact_damage_reduction + upgrade.amount) * 100.0]
		&"combat_repair":
			return "%.0f > %.0f health / 3 sec" % [player.combat_repair_amount, player.combat_repair_amount + upgrade.amount]
		&"heavy_rounds":
			return "Size: +%.0f%% > +%.0f%%\nKnockback: +%.0f%% > +%.0f%%" % [player.weapon.projectile_size_bonus * 100.0, (player.weapon.projectile_size_bonus + upgrade.amount) * 100.0, player.weapon.knockback_bonus * 100.0, (player.weapon.knockback_bonus + upgrade.secondary_value) * 100.0]
		&"piercing":
			return "%d > %d enemies pierced" % [player.weapon.pierce_count, player.weapon.pierce_count + int(upgrade.amount)]
		&"split_shot":
			return "%d > %d side shots" % [player.weapon.split_lens_level * 2, (player.weapon.split_lens_level + 1) * 2]
		&"critical":
			return "%.0f%% > %.0f%% critical chance" % [player.weapon.critical_chance * 100.0, (player.weapon.critical_chance + upgrade.amount) * 100.0]
		&"explosive":
			return "%.0f%% > %.0f%% splash damage" % [player.weapon.splash_damage_ratio * 100.0, (player.weapon.splash_damage_ratio + upgrade.amount) * 100.0]
		&"shield":
			return "%.0f > %.0f max shield" % [player.maximum_shield, player.maximum_shield + upgrade.amount]
		&"nova_pulse":
			return "%.0f > %.0f pulse damage" % [player.nova_pulse_damage_per_level * player.nova_pulse_level, player.nova_pulse_damage_per_level * (player.nova_pulse_level + 1)]
	return ""
