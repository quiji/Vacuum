extends Node2D

enum RotatingMode {NO_ROTATION, FOLLOW_POLY4}
enum CameraSetup {SETUP_CENTER, SETUP_UP}

enum CameraLook {LOOK_CENTER, LOOK_UP, LOOK_DOWN}
enum CameraSceneMode {WATER_BUBBLE, FLYING_SPACE, GRAVITY_PLATFORM}


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

var max_distance_squared = 0
var min_distance_squared = 0

var follow_margins = Rect2(20, 20, 20, 20)


#########################################################################



var lock_actor = {
	target = null,
	t = 0,
	base_position = null,
	duration = 1.0,
	speed = 270,
	locked = false
}

var follow_actor = {
	t_x = null,
	t_y = null,
	target = null,
	start = Vector2(),
	duration = 1.0
	
}

var ahead = {
	distance = 150,
	mov_duration = 1.2,
	t = null,
	on = false
}

var gravity = {
	duration = 2.0,
	t = null,
	on = false,
	target = Vector2(0, -100),
	current_position = Vector2(),
	start_position = Vector2()
}

var margins_inter = {
	t = null,
	target = Rect2(0, 0, 0, 0),
	start = Rect2(0, 0, 0, 0),
	duration = 0.4
}


var camera = null
var _actor = null

func _ready():
	camera = Camera2D.new()
	camera.set_script(preload("res://addons/quijipixel.cameraman/Camera.gd"))
	
	add_child(camera)
	Glb.set_current_camera_man(self)
	
	camera.add_action(gravity)
	
	tween = Tween.new()
	add_child(tween)
	

	
	if actor != '':
		lock_actor.locked = true
		global_position = get_node(actor).global_position
		set_actor(get_node(actor))

	change_scene_mode(FLYING_SPACE)


	max_distance_squared = max_distance * max_distance
	min_distance_squared = min_distance * min_distance
	
	#setup_camera(null, SETUP_CENTER)


	# For debug purposes
	if debug_cameraman:
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
	attempt_lock()


	
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

func attempt_lock():
	if lock_actor.target == null:
		lock_actor.locked = false
		lock_actor.target = _actor.global_position - global_position
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
		lock_actor.base_position += _actor.get_last_velocity() * delta

		lock_actor.t += delta / lock_actor.duration
		if lock_actor.t < 1:
			var y = Glb.Smooth.cam_space_mov(lock_actor.t) * lock_actor.target.y
			var x = lock_actor.t * lock_actor.target.x
			
			position = lock_actor.base_position + Vector2(x, y)
		else:
			position = lock_actor.base_position + lock_actor.target
			lock_actor.target = null
			global_position = _actor.global_position
			lock_actor.locked = true



func change_scene_mode(mode):
	scene_mode = mode

	match scene_mode:
		GRAVITY_PLATFORM:
			attempt_lock()
			change_margins(40, 60, 40, 0, true)


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

func change_margins(left_dist, up_dist, right_dist, down_dist, force=false):
	if not force:
		margins_inter.t = 0
		margins_inter.start = follow_margins
		margins_inter.target = Rect2(-left_dist, -up_dist, left_dist + right_dist, up_dist + down_dist)
	else:
		follow_margins = Rect2(-left_dist, -up_dist, left_dist + right_dist, up_dist + down_dist)
		if debug_cameraman:
			update()

func check_margins(actor_pos):
	if actor_pos.x > follow_margins.end.x:
		global_position.x = _actor.global_position.x - follow_margins.end.x
	elif actor_pos.x < follow_margins.position.x:
		global_position.x = _actor.global_position.x - follow_margins.position.x
		
	if actor_pos.y < follow_margins.position.y:
		global_position.y = _actor.global_position.y - follow_margins.position.y
	elif actor_pos.y > follow_margins.end.y:
		global_position.y = _actor.global_position.y - follow_margins.end.y



func _draw():
	if debug_cameraman:
		draw_line(Vector2(follow_margins.position.x,300), Vector2(follow_margins.position.x,-300), Color(1.0, 0.2, 0.2), 2.0)
		draw_line(Vector2(follow_margins.end.x,300), Vector2(follow_margins.end.x,-300), Color(1.0, 0.2, 0.2), 2.0)
		
		draw_line(follow_margins.position, Vector2(follow_margins.end.x, follow_margins.position.y), Color(0.2, 1.0, 0.2), 2.0)
		draw_line(follow_margins.end, Vector2(follow_margins.position.x, follow_margins.end.y), Color(0.2, 1.0, 0.2), 2.0)


"""
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
"""

func flying_space_logic(delta):
	pass



func gravity_platform_logic(delta):
	
	if lock_actor.locked:

		if _actor.is_looking_right() and gravity.target.x != -70:
			gravity.target.x = -70
			camera.camera_start_action(gravity)
		if not _actor.is_looking_right() and gravity.target.x != 70:
			gravity.target.x = 70
			camera.camera_start_action(gravity)

	
		
		var actor_pos = _actor.global_position - global_position
		check_margins(actor_pos)
		
		



func _physics_process(delta):
	#if _actor != null and _object == null:
	if _actor != null and lock_actor.locked:

		match scene_mode:
			FLYING_SPACE:
				flying_space_logic(delta)
			GRAVITY_PLATFORM:
				gravity_platform_logic(delta)
	elif _actor != null:
		reach_and_lock_actor(delta)

	if margins_inter.t != null:
		if margins_inter.t < 1:
			margins_inter.t += delta / margins_inter.duration
			margins_inter.start.position = Glb.Smooth.linear_interp(margins_inter.start.position, margins_inter.target.position, margins_inter.t)
			margins_inter.start.end = Glb.Smooth.linear_interp(margins_inter.start.end, margins_inter.target.end, margins_inter.t)
			
			follow_margins = margins_inter.start
		else:
			margins_inter.t = null
			follow_margins = margins_inter.target
		if debug_cameraman:
			update()


