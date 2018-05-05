tool
extends Node

export (bool) var play_now = false setget set_play_now, get_play_now

func set_play_now(val):
	play_now = val

	if Engine.editor_hint and play_now:
		start_theme()
	elif not play_now and Engine.editor_hint:
		stop_theme()

func get_play_now():
	return play_now

################################################
#
#  Overload methods
#
################################################

func start_theme():
	pass

func stop_theme():
	pass

