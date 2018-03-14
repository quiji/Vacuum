extends "res://classes/Stage.gd"


func _ready():
	
	install_components($playground/character)
	#$camera_crew.zoom_in()
	
func on_finished_fade_in():
	if $camera_crew.is_zoomed_in():
		$camera_crew.zoom_out()
