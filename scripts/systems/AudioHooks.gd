class_name AudioHooks
extends Node

signal cue_requested(cue_name: StringName)


func play(cue_name: StringName) -> void:
	# Audio files can be connected later without changing gameplay scripts.
	cue_requested.emit(cue_name)
