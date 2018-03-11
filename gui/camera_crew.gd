extends Node2D

enum RotatingMode {NO_ROTATION, CIRCULAR, FOLLOW_LINE, FOLLOW_POLY4, FOLLOW_CUSTOM_POLY}
enum CameraSetup {SETUP_CENTER, SETUP_UP}

enum CameraLook {LOOK_CENTER, LOOK_UP, LOOK_DOWN}
enum CameraSceneMode {WATER_BUBBLE, FLYING_SPACE, GRAVITY_PLATFORM, BLOCKED}


#########################################################################
export (NodePath) var actor

export (bool) var debug_cameraman = false
export (float) var look_distance = 100.0
#########################################################################


var scene_mode
var tween = null
var normal = Vector2(0, -1)
var target_normal = null
var water_center = null
var water_radius_limits = 0

var gravity_center = null

var rect_area = null
var camera = null
var _actor = null

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
	#duration = 2.0,
	duration = 1.5,
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
	duration = 0.0485
}

var line = {
	#duration = 1.0,
	duration = 0.8,
	t = 0,
	start = null
}


func _ready():
	camera = $camera_man
	
	Glb.set_current_camera_man(self)
	
	camera.add_action(gravity)
	camera.add_action(water)
	
	rect_area = $margin_area
	
	tween = Tween.new()
	add_child(tween)
	

	change_scene_mode(FLYING_SPACE)


	# For debug purposes
	if debug_cameraman:
		var spr = Sprite.new()
		spr.texture = preload("res://gui/camera_crew/camera.png")
		add_child(spr)

		spr = Sprite.new()
		spr.texture = preload("res://gui/camera_crew/camera.png")
		spr.modulate = Color(0.9, 4.0, 3.0, 1.0)
		camera.add_child(spr)
		
		rect_area.debug_cameraman = true



func set_actor(actor):
	_actor = actor
	#attempt_lock()


	
func get_current_normal():
	if target_normal != null:
		return target_normal
	else:
		return normal

func normal_shift(new_normal, new_target_normal):
		
	var rotation_mode = NO_ROTATION
	if gravity_center != null:
		rotation_mode = gravity_center.get_camera_rotation_mode()

	return null

	"""
	if rotation_mode != NO_ROTATION:
		var snapper = [Vector2(0, -1).rotated(gravity_center.rotation), Vector2(0, 1).rotated(gravity_center.rotation)]
		var _normal = new_normal if new_target_normal == null else new_target_normal
		var target = Glb.VectorLib.snap_to(_normal, snapper)
	
		if normal.dot(target) < 0:
			target_normal = target
			line.t = 0
			line.start = normal

	"""

	match rotation_mode:
		CIRCULAR:
			target_normal = new_normal if new_target_normal == null else new_target_normal
		
		FOLLOW_LINE:
			continue
		FOLLOW_POLY4:
			continue
		FOLLOW_CUSTOM_POLY:
			continue

			target_normal = new_normal if new_target_normal == null else new_target_normal

		FOLLOW_LINE:
			var snapper = gravity_center.get_rotation_snapper()
			var _normal = new_normal if new_target_normal == null else new_target_normal
			var target = Glb.VectorLib.snap_to(_normal, snapper)

			if normal.dot(target) < 0.8:
				target_normal = target
				line.t = 0
				line.start = normal

		FOLLOW_POLY4:
			var snapper = gravity_center.get_rotation_snapper()
			var _normal = new_normal if new_target_normal == null else new_target_normal
			var target = Glb.VectorLib.snap_to(_normal, snapper)

			target_normal = target
		FOLLOW_CUSTOM_POLY:
			var snapper = gravity_center.get_rotation_snapper()
			var _normal = new_normal if new_target_normal == null else new_target_normal
			var target = Glb.VectorLib.snap_to(_normal, snapper)
			target_normal = target

	return true

func attempt_lock():
	#if lock_actor.target == null:
	if water_center != null:
		lock_actor.objective = water_center
	else:
		lock_actor.objective = _actor

	if not rect_area.in_margins(lock_actor.objective.global_position):


		lock_actor.locked = false
		lock_actor.target = lock_actor.objective.global_position - global_position
		lock_actor.t = 0
		lock_actor.target_pos = lock_actor.objective.global_position
		lock_actor.base_position = global_position
		lock_actor.current_pos = Vector2()
		lock_actor.actor_movement = Vector2()
		var distance = lock_actor.target.length()
		if distance > 0:
			lock_actor.duration = distance / lock_actor.speed
		else:
			lock_actor.target = null
			lock_actor.locked = true

		if debug_cameraman:
			rect_area.update()


func reach_and_lock_actor(delta):
	# Reach for actor
	if lock_actor.target != null:
		
		lock_actor.actor_movement = (lock_actor.objective.global_position - lock_actor.base_position) - lock_actor.target

		lock_actor.t += delta / lock_actor.duration
		if lock_actor.t < 1:
			lock_actor.current_pos = Vector2().linear_interpolate(lock_actor.target, Glb.Smooth.cam_space_mov(lock_actor.t))
			global_position = lock_actor.actor_movement + lock_actor.base_position + lock_actor.current_pos
			if debug_cameraman:
				rect_area.update()

		else:
			lock_actor.target = null
			global_position = lock_actor.objective.global_position
			lock_actor.locked = true
		if not lock_actor.ignore_margins and rect_area.in_margins(lock_actor.objective.global_position, rect_area.INNER_MARGIN):
			lock_actor.target = null
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
			lock_actor.speed = 270
			lock_actor.ignore_margins = true
			attempt_lock()
		GRAVITY_PLATFORM:
			gravity_center = data
			lock_actor.duration = 1.0
			lock_actor.speed = 40
			lock_actor.ignore_margins = false
			attempt_lock()
			rect_area.change_margins(40, 60, 40, 10)
		WATER_BUBBLE:
			lock_actor.duration = 8.0
			lock_actor.target = null
			lock_actor.speed = 180
			lock_actor.ignore_margins = true
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

func zoom_in():
	tween.interpolate_property(camera, "zoom", camera.zoom, Vector2(0.5, 0.5), 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.start()
	
func zoom_out():
	tween.interpolate_property(camera, "zoom", camera.zoom, Vector2(1, 1), 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.start()


func flying_space_logic(delta):
	if lock_actor.locked:
		global_position = _actor.global_position


func gravity_platform_logic(delta):

	if lock_actor.locked:
		"""
		if _actor.is_looking_right() and gravity.target.x != -70:
			gravity.target = Vector2(-70, -100)
			camera.camera_start_action(gravity)
		if not _actor.is_looking_right() and gravity.target.x != 70:
			gravity.target = Vector2(70, -100)
			camera.camera_start_action(gravity)
		"""
		gravity.target = Vector2(0, -150)
		camera.camera_start_action(gravity)

	var inner_direction = (global_position - _actor.global_position).normalized()
	if rect_area.in_margins(_actor.global_position, rect_area.OUTER_MARGIN) and inner_direction.dot(_actor.get_last_velocity_normalized()) < 0:
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

	if not rect_area.in_margins(lock_actor.objective.global_position):
		if scene_mode != WATER_BUBBLE:
			if lock_actor.target == null:
				attempt_lock()


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

				normal = Glb.Smooth.radial_interpolate(normal, target_normal, Glb.Smooth.cam_circular_rot(t, d_t))
			FOLLOW_POLY4:
				var distance_factor = (normal.dot(target_normal) + 1) / 2
				normal = Glb.Smooth.radial_interpolate(normal, target_normal, delta * (1.05 + distance_factor))
			FOLLOW_LINE:
				if line.start != null:
					line.t += delta / line.duration 
					normal = Glb.Smooth.radial_interpolate(line.start, target_normal, line.t)
			FOLLOW_CUSTOM_POLY:
				var distance_factor = (normal.dot(target_normal) + 1) / 2
				normal = Glb.Smooth.radial_interpolate(normal, target_normal, delta * (1.05 + distance_factor))


		if normal.dot(target_normal) >= 0.999:
			normal = target_normal
			target_normal = null
		rotation = (-normal).angle() - PI/2
