extends Node

const VectorLib = preload("res://classes/VectorLib.gd")
const Smooth = preload("res://classes/Smoothstep.gd")
const CameraMan = preload("res://addons/quijipixel.cameraman/CameraMan.gd")

enum ReactTypes {NO_REACTION, REACT_STEP, REACT_SWIMSTROKE, REACT_ENDSWIMSTROKE}

var _collision_layer_bits = {}
var _current_camera_man = null
var debug_mode = false

func _ready():
	randomize()
	
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

func has_signal(node, signal_name):
	return node.get_script() != null and node.get_script().has_script_signal(signal_name)
	
func set_current_camera_man(man):
	_current_camera_man = man

func get_current_camera_man():
	return _current_camera_man


