class_name EndScreen
extends Control

signal restart_requested


func _ready() -> void:
	$Panel/Margin/Layout/Restart.pressed.connect(func() -> void: restart_requested.emit())
	hide()


func show_result(victory: bool, survival_time: float, defeated: int, level: int) -> void:
	$Panel/Margin/Layout/Title.text = "MISSION COMPLETE" if victory else "MISSION FAILED"
	$Panel/Margin/Layout/Title.modulate = Color("7fffd4") if victory else Color("ff786b")
	var total_seconds := maxi(0, floori(survival_time))
	$Panel/Margin/Layout/Stats.text = "SURVIVAL  %02d:%02d\nDEFEATED  %d\nLEVEL  %d" % [total_seconds / 60, total_seconds % 60, defeated, level]
	show()
	$Panel/Margin/Layout/Restart.grab_focus()
