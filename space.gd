extends Node


func _ready():
	#$playground/character.set_normal(Vector2(1, 0))
	$playground/character.set_space_velocity(Vector2(0, 1) * 25)

	$playground/water_platform.grow(60)

	#$camera_man.zoom_in()