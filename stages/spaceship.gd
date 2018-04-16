extends "res://classes/Stage.gd"


func _ready():
	install_components(IN_SHIP, $room/character)

	Glb.get_current_camera_man().change_scene_mode(Glb.CameraCrew.GRAVITY_PLATFORM, $room)
	if not $camera_crew.is_zoomed_in():
		$camera_crew.zoom_in(true)

