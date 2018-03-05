extends Node2D

enum RotatingMode {NO_ROTATION, CIRCULAR, FOLLOW_POLY4}
enum CameraSetup {SETUP_CENTER, SETUP_UP}

enum CameraLook {LOOK_CENTER, LOOK_UP, LOOK_DOWN}
enum CameraSceneMode {WATER_BUBBLE, FLYING_SPACE, GRAVITY_PLATFORM, BLOCKED}


#########################################################################
export (NodePath) var actor
export (int, "WaterBubble", "FlyingSpace", "GravityPlatform") var scene_mode
export (bool) var debug_cameraman = true
#########################################################################

export (float) var max_speed = 300.0
export (float) var min_speed = 190.0
export (float) var max_distance = 300.0
export (float) var min_distance = 4.5
export (float) var setup_distance = 104.5
export (float) var look_distance = 100.0

var tween = null
var _object = null
var _camera_setup = -1

var normal = Vector2(0, -1)
var target_normal = null




#########################################################################



var lock_actor = {
	target = null,
	t = 0,
	base_position = null,
	duration = 1.0,
	speed = 270,
	locked = false,
	objective = null
}



var gravity = {
	duration = 2.0,
	t = null,
	on = false,
	target = Vector2(0, -100),
	current_position = Vector2(),
	start_position = Vector2(),
	method = "cam_space_mov"
}

var water = {
	duration = 2.0,
	t = null,
	on = false,
	target = Vector2(0, -100),
	current_position = Vector2(),
	start_position = Vector2(),
	method = "cam_water_mov"
}

var circular = {
	#duration for a full circle rotation
	duration = 0.2
}



var water_center = null
var water_radius_limits = 0

var gravity_center = null

var rect_area = null
var camera = null
var _actor = null

func _ready():
	camera = Camera2D.new()
	camera.set_script(preload("res://addons/quijipixel.cameraman/Camera.gd"))
	
	add_child(camera)
	Glb.set_current_camera_man(self)
	
	camera.add_action(gravity)
	camera.add_action(water)
	
	rect_area = Area2D.new()
	rect_area.set_script(preload("res://addons/quijipixel.cameraman/MarginArea.gd"))
	add_child(rect_area)
	
	
	tween = Tween.new()
	add_child(tween)
	

	
	if actor != '':
		lock_actor.locked = true
		global_position = get_node(actor).global_position
		set_actor(get_node(actor))

	change_scene_mode(FLYING_SPACE)


	# For debug purposes
	if debug_cameraman:
		var spr = Sprite.new()
		spr.texture = preload("res://addons/quijipixel.cameraman/icon.png")
		add_child(spr)

		spr = Sprite.new()
		spr.texture = preload("res://addons/quijipixel.cameraman/icon.png")
		spr.modulate = Color(0.9, 4.0, 3.0, 1.0)
		camera.add_child(spr)
		
		rect_area.debug_cameraman = true



func set_actor(actor):
	_actor = actor
	attempt_lock()


	
func get_current_normal():
	if target_normal != null:
		return target_normal
	else:
		return normal

func normal_shift(new_normal, new_target_normal):
		
	var rotation_mode = NO_ROTATION
	if gravity_center != null:
		rotation_mode = gravity_center.get_camera_rotation_mode()

		Console.add_log("rotation_mode", rotation_mode)

	match rotation_mode:
		CIRCULAR:
			target_normal = new_normal if new_target_normal == null else new_target_normal
		FOLLOW_POLY4:
			var _normal = new_normal if new_target_normal == null else new_target_normal
			var target = Glb.VectorLib.snap_to(_normal, Glb.VectorLib.POLY4)

			target_normal = target

	
	return true

func attempt_lock():
	if lock_actor.target == null:

		if water_center != null:
			lock_actor.objective = water_center
		else:
			lock_actor.objective = _actor

		lock_actor.locked = false
		lock_actor.target = lock_actor.objective.global_position - global_position
		lock_actor.t = 0
		lock_actor.base_position = position
		var distance = lock_actor.target.length()
		if distance > 0:
			lock_actor.duration = distance / lock_actor.speed
		else:
			lock_actor.target = null
			lock_actor.locked = true

func reach_and_lock_actor(delta):
	# Reach for actor
	if lock_actor.target != null:
		lock_actor.base_position += lock_actor.objective.get_last_velocity() * delta

		lock_actor.t += delta / lock_actor.duration
		if lock_actor.t < 1:
			var y = Glb.Smooth.cam_space_mov(lock_actor.t) * lock_actor.target.y
			var x = lock_actor.t * lock_actor.target.x
			
			position = lock_actor.base_position + Vector2(x, y)
		else:
			position = lock_actor.base_position + lock_actor.target
			lock_actor.target = null
			global_position = lock_actor.objective.global_position
			lock_actor.locked = true



func change_scene_mode(mode, data=null):
	
	if scene_mode != mode:
		match scene_mode:
			GRAVITY_PLATFORM:
				camera.camera_end_action(gravity)
				gravity_center = null
			WATER_BUBBLE:
				camera.camera_end_action(water)
				water_center = null

	scene_mode = mode
	
	match scene_mode:
		FLYING_SPACE:
			attempt_lock()
		GRAVITY_PLATFORM:
			gravity_center = data
			lock_actor.duration = 1.0
			lock_actor.speed = 270
			attempt_lock()
			rect_area.change_margins(40, 60, 40, 0)
		WATER_BUBBLE:
			lock_actor.duration = 8.0
			lock_actor.target = null
			lock_actor.speed = 180
			water_center = data
			var r = water_center.get_radius() / 80
			water_radius_limits = 30 * r
			rect_area.change_margins(water_radius_limits, water_radius_limits, water_radius_limits, water_radius_limits)

			attempt_lock()


func look_direction(dir):
		
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

func flying_space_logic(delta):
	if lock_actor.locked:
		global_position = _actor.global_position


func gravity_platform_logic(delta):
	
	if lock_actor.locked:

		if _actor.is_looking_right() and gravity.target.x != -70:
			gravity.target = Vector2(-70, -100)
			camera.camera_start_action(gravity)
		if not _actor.is_looking_right() and gravity.target.x != 70:
			gravity.target = Vector2(70, -100)
			camera.camera_start_action(gravity)
	
		if not rect_area.in_margins(_actor.global_position):
			global_position += _actor.get_last_velocity() * delta

func water_bubble_logic(delta):
	if lock_actor.locked:
		
		if not rect_area.in_margins(_actor.global_position):

			var distance = water_center.get_inner_limit_radius() * 1.05
			var direction = transform.xform_inv(_actor.global_position)
			
			direction = Glb.VectorLib.snap_to(direction, Glb.VectorLib.POLY8)
			if direction.normalized().dot(water.target.normalized()) != 1:
				water.target = direction * distance

				camera.camera_start_action(water)


		elif water.target != Vector2():

			water.target = Vector2()
			camera.camera_start_action(water)
			attempt_lock()
			



func _physics_process(delta):

	if _actor != null and lock_actor.locked:

		match scene_mode:
			FLYING_SPACE:
				flying_space_logic(delta)
			GRAVITY_PLATFORM:
				gravity_platform_logic(delta)
			WATER_BUBBLE:
				water_bubble_logic(delta)
	elif _actor != null:
		reach_and_lock_actor(delta)


	if target_normal != null:
		
		var rotation_mode = NO_ROTATION
		if gravity_center != null:
			rotation_mode = gravity_center.get_camera_rotation_mode()

		match rotation_mode:
			CIRCULAR:
				# this is the d_t that will blend different rotation speeds depending of normal - target_normal distance
				var d_t = (normal.dot(target_normal) + 1) / 2
				# this is the t for a whole circle rotation
				var t = delta / circular.duration * (1 - d_t)
				Console.add_log("circle_percentage", 1 - d_t)
				Console.add_log("piece_duration", circular.duration * (1 - d_t))

				normal = normal.linear_interpolate(target_normal, Glb.Smooth.cam_circular_rot(t, d_t))
			FOLLOW_POLY4:
				var distance_factor = (normal.dot(target_normal) + 1) / 2
				normal = normal.linear_interpolate(target_normal, delta * (1.05 + distance_factor))

		rotation = (-normal).angle() - PI/2
		if normal.dot(target_normal) >= 0.999:
			target_normal = null
	
