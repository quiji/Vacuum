extends "res://classes/Stage.gd"


func _ready():
	install_components($room/character)

	Glb.get_current_camera_man().change_scene_mode(Glb.CameraCrew.GRAVITY_PLATFORM, $room)
	$camera_crew.zoom_in()
