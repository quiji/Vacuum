extends "res://classes/Stage.gd"


func _ready():
	
	install_components($playground/character)
	$camera_crew.zoom_in()