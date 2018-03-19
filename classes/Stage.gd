extends Node2D

var black_background_color = Color("#211a22")

var camera_crew = null
var hud = null

var door_to_spawn = null

func install_components(player):
	if door_to_spawn != null:
		var doors = get_tree().get_nodes_in_group("doors")
		for door in doors:
			player.position = door.position

	camera_crew = preload("res://gui/camera_crew.tscn").instance()
	camera_crew.set_name("camera_crew")
	camera_crew.set_actor(player)
	add_child(camera_crew)
	
	hud = preload("res://gui/hud.tscn").instance()
	hud.set_name("hud")
	add_child(hud)

	$tween.interpolate_property($blackout, "color", $blackout.color, Color(1, 1, 1), 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN, 0.5)
	$tween.start()


func spawn_on_door(door_id):
	door_to_spawn = door_id

func preinstall():
	var blackout = CanvasModulate.new()
	blackout.set_name("blackout")
	blackout.color = black_background_color
	add_child(blackout)
	
	var tween = Tween.new()
	tween.set_name("tween")
	add_child(tween)
	tween.connect("tween_completed", self, "on_tween_completed")
	
var target_stage = null
var door_id = null
func fade_towards(target, door):
	target_stage = target
	door_id = door
	$tween.interpolate_property($blackout, "color", $blackout.color, black_background_color, 1.0, Tween.TRANS_CUBIC, Tween.EASE_IN, 0.5)
	$tween.start()
	
func on_tween_completed(object, key):
	if target_stage != null:
		on_finished_fade_out()
		Glb.load_stage(target_stage, door_id)
	else:
		on_finished_fade_in()



########################################################################################
#
#                                 Virtual methods
#
########################################################################################

func on_finished_fade_in():
	pass
	
func on_finished_fade_out():
	pass