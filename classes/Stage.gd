extends Node2D

var camera_crew = null
var hud = null
	
func install_components(player):
	camera_crew = preload("res://gui/camera_crew.tscn").instance()
	camera_crew.set_name("camera_crew")
	camera_crew.set_actor(player)
	add_child(camera_crew)
	
	hud = preload("res://gui/hud.tscn").instance()
	hud.set_name("hud")
	add_child(hud)