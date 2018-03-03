extends Node2D

enum RotatingMode {NO_ROTATION, FOLLOW_POLY4}
enum CameraSetup {SETUP_CENTER, SETUP_UP}

enum CameraLook {LOOK_CENTER, LOOK_UP, LOOK_DOWN}
enum CameraFilmMode {WATER_BUBBLE, FLYING_SPACE, GRAVITY_PLATFORM}


# Who to follow
export (NodePath) var actor
export (float) var max_speed = 300.0
export (float) var min_speed = 190.0
export (float) var max_distance = 300.0
export (float) var min_distance = 4.5
export (float) var setup_distance = 104.5
export (bool) var show_camera_man = true
export (float) var look_distance = 100.0

var camera = null
var tween = null
var _actor = null
var _object = null
var _camera_setup = -1

var normal = Vector2(0, -1)
var target_normal = null

var max_distance_squared = 0
var min_distance_squared = 0

func _ready():
	camera = Camera2D.new()
	camera.current = true
	camera.rotating = true
	#camera.drag_margin_h_enabled = false
	#camera.drag_margin_v_enabled = false
	
	#camera.smoothing_enabled = true
	#camera.drag_margin_top = 0.4
	#camera.drag_margin_bottom = 0
	#camera.drag_margin_right = 0.2
	#camera.drag_margin_left = 0.2
	
	add_child(camera)
	Glb.set_current_camera_man(self)
	
	tween = Tween.new()
	add_child(tween)
	
	if actor != '':
		set_actor(get_node(actor))

	max_distance_squared = max_distance * max_distance
	min_distance_squared = min_distance * min_distance
	
	setup_camera(null, SETUP_CENTER)

	# For debug purposes
	if show_camera_man:
		var spr = Sprite.new()
		spr.texture = preload("res://addons/quijipixel.cameraman/icon.png")
		add_child(spr)

		spr = Sprite.new()
		spr.texture = preload("res://addons/quijipixel.cameraman/icon.png")
		spr.modulate = Color(0.9, 4.0, 3.0, 1.0)
		camera.add_child(spr)

	Console.add_log(self, "_object")

func set_actor(actor):
	_actor = actor

	
	#tween.stop(self, "reach_actor")
	#tween.interpolate_method(self, "reach_actor", 0, 100, 2.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	#tween.start()

func reach_actor(value):
	value = 1 - value / 100
	var target = _actor.position - position
	#var target_length_squared = target.length_squared

	position += target * value
	"""
	var total = target / value
	355
	0.4
	"""
	
func get_current_normal():
	if target_normal != null:
		return target_normal
	else:
		return normal

func normal_shift(request_from, new_normal, new_target_normal, rotation_mode):
	if request_from != null and request_from != _actor:
		return false
		
	if rotation_mode == FOLLOW_POLY4:
		var _normal = new_normal
		if new_target_normal != null:
			_normal = new_target_normal
		var target = Glb.VectorLib.snap_to(_normal, Glb.VectorLib.POLY4)
		#if normal.dot(target) <= 0.2:
		target_normal = target
	
	return true

func setup_camera(request_from, dir, obj = null):
	if request_from != null and request_from != _actor:
		return false
	_object = obj
	if dir == SETUP_CENTER && _camera_setup != SETUP_CENTER:
		if _object == null:
			tween.stop(camera, "position")
			tween.interpolate_property(camera, "position", camera.position, Vector2(), 2.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			tween.start()
		else:
			tween.stop(self, "global_position")
			tween.stop(camera, "position")
			tween.interpolate_property(camera, "position", camera.position, Vector2(), 2.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			tween.interpolate_property(self, "global_position", global_position, _object.global_position, 2.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			tween.start()
		_camera_setup = SETUP_CENTER
		camera.drag_margin_top = 0
		camera.drag_margin_bottom = 0
		camera.drag_margin_right = 0.1
		camera.drag_margin_left = 0.1

	if dir == SETUP_UP && _camera_setup != SETUP_UP:
		if _object == null:
			tween.stop(camera, "position")
			tween.interpolate_property(camera, "position", camera.position, Vector2(0, -1) * setup_distance, 2.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			tween.start()
		else:
			tween.stop(self, "global_position")
			tween.stop(camera, "position")
			tween.interpolate_property(camera, "position", camera.position, Vector2(0, -1) * setup_distance, 2.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			tween.interpolate_property(self, "global_position", global_position, _object.global_position, 2.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			tween.start()
		_camera_setup = SETUP_UP
		camera.drag_margin_top = 0.4
		camera.drag_margin_bottom = 0
		camera.drag_margin_right = 0.2
		camera.drag_margin_left = 0.2

	if _camera_setup == SETUP_CENTER:
		Console.add_log("Camera_setup", "CENTER")
	else:
		Console.add_log("Camera_setup", "UP")
		
	return true

func look_direction(request_from, dir):
	if request_from != null and request_from != _actor:
		return false
		
	match dir:
		LOOK_UP:
			tween.stop(camera, "offset")
			tween.interpolate_property(camera, "offset", Vector2(), get_current_normal() * look_distance, 2.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			tween.start()
		LOOK_DOWN:
			tween.stop(camera, "offset")
			tween.interpolate_property(camera, "offset", Vector2(), -get_current_normal() * look_distance, 2.5, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			tween.start()
		LOOK_CENTER:
			tween.stop(camera, "offset")
			tween.interpolate_property(camera, "offset", camera.offset, Vector2(), 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
			tween.start()

	return true

func _physics_process(delta):
	if _actor != null and _object == null:
		var move_direction = _actor.global_position - global_position
		var speed = 100
		var distance_squared = move_direction.length_squared()
		
		
		if  distance_squared > 100 *100:
			speed = 200
		
		if distance_squared > min_distance_squared:
			var distance_factor = (clamp(distance_squared, min_distance_squared, max_distance_squared) - min_distance_squared) / (max_distance_squared - min_distance_squared)
			speed = clamp(max_speed * distance_factor, min_speed, max_speed)
			position += move_direction.normalized() * speed * delta
		else:
			global_position = _actor.global_position

	if target_normal != null:
		var distance_factor = (normal.dot(target_normal) + 1) / 2
		
		normal = normal.linear_interpolate(target_normal, delta * (1.05 + distance_factor))
		rotation = (-normal).angle() - PI/2
		if normal.dot(target_normal) >= 0.999:
			target_normal = null


	