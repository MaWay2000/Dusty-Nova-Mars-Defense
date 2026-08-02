class_name InputController
extends Node

var mobile_direction: Vector2 = Vector2.ZERO


func _ready() -> void:
	_add_key_if_missing("move_left", KEY_A, true)
	_add_key_if_missing("move_left", KEY_LEFT)
	_add_key_if_missing("move_right", KEY_D, true)
	_add_key_if_missing("move_right", KEY_RIGHT)
	_add_key_if_missing("move_up", KEY_W, true)
	_add_key_if_missing("move_up", KEY_UP)
	_add_key_if_missing("move_down", KEY_S, true)
	_add_key_if_missing("move_down", KEY_DOWN)
	_add_key_if_missing("pause_game", KEY_ESCAPE)


func get_movement_direction() -> Vector2:
	if mobile_direction.length_squared() > 0.001:
		return mobile_direction.normalized()
	return Input.get_vector("move_left", "move_right", "move_up", "move_down").normalized()


func set_mobile_direction(direction: Vector2) -> void:
	mobile_direction = direction.limit_length(1.0)


func _add_key_if_missing(action: StringName, keycode: Key, physical: bool = false) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for existing_event: InputEvent in InputMap.action_get_events(action):
		if existing_event is InputEventKey:
			var existing_key := existing_event as InputEventKey
			if (physical and existing_key.physical_keycode == keycode) or (not physical and existing_key.keycode == keycode):
				return
	var event := InputEventKey.new()
	if physical:
		event.physical_keycode = keycode
	else:
		event.keycode = keycode
	InputMap.action_add_event(action, event)
