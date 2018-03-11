extends Node2D

const VectorLib = preload("res://classes/VectorLib.gd")
const Smooth = preload("res://classes/Smoothstep.gd")
const CameraCrew = preload("res://gui/camera_crew.gd")

enum ReactTypes {NO_REACTION, REACT_STEP, REACT_SWIMSTROKE, REACT_ENDSWIMSTROKE}

var _collision_layer_bits = {}
var _current_camera_man = null
var debug_mode = false


func _ready():
	randomize()

	set_process(false)
	
	debug_mode = ProjectSettings.get_setting("Project/debug_mode")
	
	OS.window_maximized = not debug_mode
	
	var i = 1
	var setting_name = "layer_names/2d_physics/layer_"
	while i < 21:
		var layer = ProjectSettings.get_setting(setting_name+str(i))
		_collision_layer_bits[layer] = i - 1
		i += 1


func get_collision_layer_int(layers):
	var layers_int = 0
	for layer in layers:
		layers_int += pow(2, _collision_layer_bits[layer])
	return layers_int

func get_collision_layer_id(layer):
	return _collision_layer_bits[layer]


func has_signal(node, signal_name):
	return node.get_script() != null and node.get_script().has_script_signal(signal_name)
	
func set_current_camera_man(man):
	_current_camera_man = man

func get_current_camera_man():
	return _current_camera_man



######### Scene loading
var stages = {
	space = "res://stages/space.tscn",
	spaceship = "res://stages/spaceship.tscn"
}

var loader
var wait_frames
var time_max = 100 # msec
var current_scene = null
var from_door = null

func load_stage(stage, door_id=null):
	# In the future, here we handle the areas and loading of all that stuff....
	if stages.has(stage):
		print("loading: ", stages[stage])
		from_door = door_id
		_load_new_scene(stages[stage])


func _load_new_scene(scene):
	loader = ResourceLoader.load_interactive(scene)
	if loader == null: # check for errors
		return
	set_process(true)
	
	if current_scene != null:
		current_scene.queue_free()

	wait_frames = 1

func _process(delta):

	if loader == null:
		# no need to process anymore
		set_process(false)
		return

	if wait_frames > 0: # wait for frames to let the "loading" animation to show up
		wait_frames -= 1
		return

	var t = OS.get_ticks_msec()

	while OS.get_ticks_msec() < t + time_max: # use "time_max" to control how much time we block this thread

		# poll your loader
		var err = loader.poll()

		if err == ERR_FILE_EOF: # load finished
			var resource = loader.get_resource()
			loader = null
			set_new_scene(resource)
			break
		elif err == OK:
			update_progress()
		else: # error during loading
			loader = null
			break

func update_progress():
	var progress = float(loader.get_stage()) / loader.get_stage_count()
	# update your progress bar?
	get_node("progress").percent_visible = progress
	$label.text = str(progress)

func set_new_scene(scene_resource):

	current_scene = scene_resource.instance()
	if from_door != null and current_scene.has_method("spawn_on_door"):
		current_scene.spawn_on_door(from_door)
	current_scene.preinstall()
	get_tree().get_root().add_child(current_scene)

