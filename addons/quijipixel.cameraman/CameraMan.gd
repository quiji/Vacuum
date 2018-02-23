extends Node2D

enum RotatingMode {NO_ROTATION, FOLLOW_POLY4}
enum CameraSetup {CENTER, UP}

# Who to follow
export (NodePath) var actor
export (float) var max_speed = 300.0
export (float) var min_speed = 190.0
export (float) var max_distance = 300.0
export (float) var min_distance = 4.5
export (float) var setup_distance = 104.5
export (bool) var show_camera_man = true


var camera = null
var tween = null
var _actor = null
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
	
	camera.smoothing_enabled = true
	camera.drag_margin_top = 0.4
	camera.drag_margin_bottom = 0
	camera.drag_margin_right = 0.2
	camera.drag_margin_left = 0.2
	
	add_child(camera)
	Glb.set_current_camera_man(self)
	
	tween = Tween.new()
	add_child(tween)
	
	if actor != '':
		set_actor(get_node(actor))

	max_distance_squared = pow(max_distance, 2.0)
	min_distance_squared = pow(min_distance, 2.0)
	
	setup_camera(UP)

	# For debug purposes
	if show_camera_man:
		var spr = Sprite.new()
		spr.texture = preload("res://addons/quijipixel.cameraman/icon.png")
		add_child(spr)

		spr = Sprite.new()
		spr.texture = preload("res://addons/quijipixel.cameraman/icon.png")
		spr.modulate = Color(0.9, 4.0, 3.0, 1.0)
		camera.add_child(spr)


func set_actor(actor):
	if _actor != null:
		if Glb.has_signal(_actor, "normal_shift"):
			_actor.disconnect("normal_shift", self, "on_actors_normal_shift")


	_actor = actor
	if Glb.has_signal(_actor, "normal_shift"):
		_actor.connect("normal_shift", self, "on_actors_normal_shift")


func get_current_normal():
	if target_normal != null:
		return target_normal
	else:
		return normal

func on_actors_normal_shift(new_normal, new_target_normal, rotation_mode):

	if rotation_mode == FOLLOW_POLY4:
		var _normal = new_normal
		if new_target_normal != null:
			_normal = new_target_normal
		var target = VectorLib.snap_to(_normal, VectorLib.POLY4)
		#if normal.dot(target) <= 0.2:
		target_normal = target

func setup_camera(dir):
	if dir == CameraSetup.CENTER && _camera_setup != CameraSetup.CENTER:
		tween.interpolate_property(camera, "position", camera.position, Vector2(), 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tween.start()
		_camera_setup = CameraSetup.CENTER
		camera.drag_margin_top = 0
		camera.drag_margin_bottom = 0
		camera.drag_margin_right = 0.1
		camera.drag_margin_left = 0.1

	if dir == CameraSetup.UP && _camera_setup != CameraSetup.UP:
		tween.interpolate_property(camera, "position", camera.position, Vector2(0, -1) * setup_distance, 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
		tween.start()
		_camera_setup = CameraSetup.UP
		camera.drag_margin_top = 0.4
		camera.drag_margin_bottom = 0
		camera.drag_margin_right = 0.2
		camera.drag_margin_left = 0.2


func _physics_process(delta):
	if _actor != null:
		var move_direction = _actor.global_position - global_position
		var speed = 100
		var distance_squared = move_direction.length_squared()
		
		
		if  distance_squared > pow(100, 2.0):
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


	