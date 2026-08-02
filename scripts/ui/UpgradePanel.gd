class_name UpgradePanel
extends Control

signal choice_selected(index: int)
signal reroll_requested

@onready var buttons: Array[Button] = [
	$Panel/Margin/Layout/Choices/Choice1,
	$Panel/Margin/Layout/Choices/Choice2,
	$Panel/Margin/Layout/Choices/Choice3,
]
@onready var card_labels: Array[RichTextLabel] = [
	$Panel/Margin/Layout/Choices/Choice1/CardText,
	$Panel/Margin/Layout/Choices/Choice2/CardText,
	$Panel/Margin/Layout/Choices/Choice3/CardText,
]
@onready var reroll_button: Button = $Panel/Margin/Layout/Reroll


func _ready() -> void:
	for index: int in buttons.size():
		buttons[index].pressed.connect(_on_button_pressed.bind(index))
	reroll_button.pressed.connect(func() -> void: reroll_requested.emit())
	hide()


func show_choices(upgrades: Array[UpgradeData], current_levels: Dictionary, rerolls_remaining: int, bonuses: Array[String], previews: Array[String]) -> void:
	for index: int in mini(buttons.size(), upgrades.size()):
		var upgrade := upgrades[index]
		card_labels[index].text = _choice_text(upgrade, int(current_levels.get(upgrade.upgrade_id, 0)), bonuses[index], previews[index])
	reroll_button.text = "REROLL (%d)" % rerolls_remaining
	reroll_button.disabled = rerolls_remaining <= 0
	show()
	buttons[0].grab_focus()


func hide_choices() -> void:
	hide()


func _on_button_pressed(index: int) -> void:
	choice_selected.emit(index)


func _choice_text(upgrade: UpgradeData, current_level: int, bonus_text: String, value_preview: String) -> String:
	var maximum := "∞" if upgrade.max_level <= 0 else str(upgrade.max_level)
	var rarity_color := upgrade.get_rarity_color().to_html(false)
	return "[center][color=#%s][font_size=32][b]%s[/b][/font_size]\n[font_size=19]%s | LVL %d > %d/%s[/font_size][/color]\n[color=#4c8a92][hr][/color]\n[color=#e8f2f3][font_size=23][b]%s[/b][/font_size][/color]\n[color=#4c8a92][hr][/color]\n[color=#c8d9dc][font_size=22]%s[/font_size][/color][/center]" % [
		rarity_color,
		upgrade.title,
		upgrade.get_rarity_name(),
		current_level,
		current_level + 1,
		maximum,
		bonus_text,
		value_preview,
	]
