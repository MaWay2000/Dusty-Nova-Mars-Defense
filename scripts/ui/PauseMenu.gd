class_name PauseMenu
extends Control

signal resume_requested
signal restart_requested
signal menu_requested
signal quit_requested

@onready var hint_label: Label = $Panel/Margin/Layout/Hint


func _ready() -> void:
	$Panel/Margin/Layout/Resume.pressed.connect(func() -> void: resume_requested.emit())
	$Panel/Margin/Layout/Restart.pressed.connect(func() -> void: restart_requested.emit())
	$Panel/Margin/Layout/MainMenu.pressed.connect(func() -> void: menu_requested.emit())
	$Panel/Margin/Layout/Quit.pressed.connect(func() -> void: quit_requested.emit())
	$Panel/Margin/Layout/Quit.visible = not OS.has_feature("mobile")
	hide()


func open() -> void:
	hint_label.text = ""
	show()
	$Panel/Margin/Layout/Resume.grab_focus()


func close() -> void:
	hide()


func show_main_menu_placeholder() -> void:
	hint_label.text = "Main menu will be added in a later milestone."
