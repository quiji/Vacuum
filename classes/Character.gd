extends KinematicBody2D

######## Constants #########

# Normal constants
const TOWARDS_TANGENT = 0
const TOWARDS_TARGET = 1
const TOWARDS_NEW_VALUE = 2

# facing directions, right is clockwise, left is counter clockwise
const FACING_LEFT = -1
const FACING_RIGHT = 1

const INV_INVERTED = -1
const INV_NORMAL = 1

enum ControlMode {ROTATION, INVERSION}

signal swim
signal normal_shift


######## Physics/Movement #########
var _altitude_velocity_scalar = 0.0

var _move_velocity_scalar = 0.0
var _target_move_velocity_scalar = 0.0

var _prev_altitude_velocity_scalar = 0

var _last_velocity = Vector2()
var swim_velocity = Vector2()
var space_velocity = Vector2()

######## Slope related #########

var _slope_stop_min_vel = 0
var _max_bounce = 4
var _max_angle = 0.795398


######## Gravity #########

var _gravity_center = null
var _gravity_scalar = 0.0

######## Water #########

var _water_center = null
var _water_resistance_multiplier = 1

######## Open Space #########

var _open_space = null

######## Normal #########

var _normal = Vector2(0, -1)
var _target_normal_direction = 0
var _target_normal = null

######## Misc #########
var _facing = FACING_RIGHT
# Invert controls!
var _invertor = FACING_RIGHT
var changing_center = false

######## Deltas #########
var _loosed_ground_delta = 0
var _swim_impulse_delta = 0


######## States #########
var _on_ground = false
var _falling = true
var _moving = false
var _attempting_jump = false
var _rolling = false

######## Configuration #########
var _control_mode = ROTATION
var _playable = false

############
# Init methods
############

func _ready():

	var new_parent = get_parent()
	while _open_space == null:
		if new_parent.has_method("is_open_space"):
			_open_space = new_parent
		else:
			new_parent = new_parent.get_parent()

	#Console.l(self, "_altitude_velocity_scalar")
	Console.l(self, "_falling")
	Console.l(self, "_on_ground")
	Console.l(self, "_rolling")

	Console.l(self, "_gravity_center")
	Console.l(self, "_water_center")

############
# Accesors methods
############

func set_slope_stop_min_vel(val):
	_slope_stop_min_vel = val

func set_invertor(direction):
	_invertor = direction

func get_invertor():
	return _invertor

func check_inversion():
	var _prev_inversion = _invertor
	if inversion_criteria_met(_normal):
		_invertor = INV_INVERTED
	else:
		_invertor = INV_NORMAL
	
	return _prev_inversion != _invertor


func set_facing(direction):


	_facing = direction

	#if _invertor == INV_INVERTED:
	#	if direction == FACING_LEFT:
	#		direction = FACING_RIGHT
	#	else:
	#		direction = FACING_LEFT

	change_sprite_direction(direction * _invertor)

func get_facing():
	return _facing


func set_gravity_center(center):
	if center != null:
		
		if _gravity_center != null:
			_gravity_center.remove_collision_exception_with(self)
		
		_gravity_center = center
		var rot = global_rotation
		var pos = global_position

		get_parent().remove_child(self)
		_gravity_center.add_child(self)
		_gravity_center.add_collision_exception_with(self)
		global_rotation = rot
		global_position = pos
		

		#move_and_collide(Vector2())
		#move_and_collide(_last_velocity.normalized() * -1)
		on_gravity_center_changed()
		

		# what functionality??
	else:
		if _gravity_center != null:
			_gravity_center.remove_collision_exception_with(self)
		_gravity_center = null


func set_water_center(center):
	if center != null:
		var resistance = abs(center.get_water_resistance_scalar())
		var dir = (center.global_position - global_position).normalized() 
		var vel =  clamp(_last_velocity.length(), 90, resistance * 1.5)

		if vel < resistance:
			_water_resistance_multiplier = 0.7


		swim_velocity = (_last_velocity.normalized() + dir * 1.4).normalized() * vel
		_water_center = center
	else:
		_water_center = null

func set_open_space_center():
	space_velocity = _last_velocity

func set_space_velocity(v):
	space_velocity = v

enum ParentTypes {PARENT_SPACE, PARENT_GRAVITY_PLATFORM, PARENT_WATER}
func fix_parents():
	if not changing_center:
		return false
	
	var parent_type = PARENT_SPACE
	var new_center = null
	if is_on_water_center() and _water_center != get_parent():
		new_center = _water_center
		parent_type = PARENT_WATER
	#elif is_on_gravity_center():# and _gravity_center != get_parent():
	#	_gravity_center.add_collision_exception_with(self)
	elif _open_space != get_parent():
		new_center = _open_space
		parent_type = PARENT_SPACE
	if new_center != null:
		
		var pos = global_position
		get_parent().remove_child(self)
		new_center.add_child(self)
		global_position = pos

		if parent_type == PARENT_WATER:

			# ask platform for child position
			new_center.move_child(self, 0)
			entered_water(new_center)
		elif parent_type == PARENT_SPACE:
			if was_water_center:
				left_water()

	changing_center = false

	return true

var was_water_center = false
func change_center(new_center):
	
	if new_center == null:
		was_water_center = _water_center != null
		set_gravity_center(null)
		set_water_center(null)
		set_open_space_center()
		changing_center = true
		if is_playable():
			# CameraSetup.Center
			Glb.get_current_camera_man().setup_camera(0)
	elif new_center.has_method("get_gravity_from_center"):
		was_water_center = _water_center != null
		set_gravity_center(new_center)
		set_water_center(null)
		#changing_center = true
		if is_playable():
			# CameraSetup.Up
			Glb.get_current_camera_man().setup_camera(1)
		if was_water_center:
			left_water()
	elif new_center.has_method("get_water_resistance_scalar"):
		set_water_center(new_center)
		set_gravity_center(null)
		changing_center = true
		if is_playable():
			# CameraSetup.Center
			Glb.get_current_camera_man().setup_camera(0)

func get_normal():
	return _normal

func set_playable(p):
	_playable = p

func is_playable():
	return _playable

func set_gravity_scalar(g):
	_gravity_scalar = g

func get_gravity_scalar():
	return _gravity_scalar

func get_last_velocity():
	return _last_velocity

func is_falling():
	return _falling
	
func is_on_ground():
	return _on_ground or _loosed_ground_delta < 0.025

func is_moving():
	return _moving

func is_rolling():
	return _rolling

func is_idle():
	return not _rolling and not _moving and not _falling and is_on_ground()

func set_rolling(value):
	_rolling = value

func is_on_gravity_center():
	return _gravity_center != null and _water_center == null

func is_on_water_center():
	return _water_center != null and _gravity_center == null

func is_on_space():
	return _water_center == null and _gravity_center == null

func is_water_center(center):
	return _water_center == center

func is_control_mode(mode):
	return _control_mode == mode


############
# Movement methods
############


func jump(jump_initial_velocity_scalar):
	_altitude_velocity_scalar = jump_initial_velocity_scalar
	_prev_altitude_velocity_scalar = 0
	_on_ground = false
	_falling = false
	_rolling = false
	_attempting_jump = true

func stop_in_air():
	_prev_altitude_velocity_scalar = _altitude_velocity_scalar
	_altitude_velocity_scalar = -5
	_attempting_jump = false



func move(velocity, new_facing=null):
	
	if new_facing != null:
		set_facing(new_facing)
	
	_target_move_velocity_scalar = velocity * _facing * _invertor
	_moving = true


func stop(keep=true):
	if not keep:
		_target_move_velocity_scalar = 0
	_moving = false
	
	if is_control_mode(ROTATION):
		_invertor = INV_NORMAL
	


func tilt(direction):
	_target_normal = direction

func stop_tilt():
	_target_normal = null

func update_normal():
	global_rotation = (-_normal).angle() - PI/2
	
	var rotation_mode = 1 # follow_poly4
	if is_on_water_center() or is_on_space():
		rotation_mode = 0 # no_rotation
	elif is_on_gravity_center():
		pass

	emit_signal("normal_shift", _normal, $ground_raycast.get_normal(), rotation_mode)

func add_swim_impulse(swim_impulse_scalar):
	if _swim_impulse_delta == 0:
		_water_resistance_multiplier = 1
		swim_velocity += _normal * swim_impulse_scalar
		_swim_impulse_delta = 0.3
		emit_signal("swim", position, swim_velocity)

func increase_water_resistance():
	_water_resistance_multiplier = 1.8

############
# Helper methods
############


func interpolate_normal_towards(inter_type, val=null):
	var acc = 0.1
	
	if inter_type == TOWARDS_TANGENT:
		#_normal = _normal.linear_interpolate(_normal.tangent() * _target_normal_direction, acc).normalized()
		_normal = _normal.linear_interpolate(VectorLib.snap_to(_normal.tangent(), VectorLib.POLY16) * _target_normal_direction, acc).normalized()
	elif inter_type == TOWARDS_TARGET:
		#_normal = _normal.linear_interpolate(_target_normal, acc).normalized()
		_normal = _normal.linear_interpolate(VectorLib.snap_to(_target_normal, VectorLib.POLY16), acc).normalized()
	elif inter_type == TOWARDS_NEW_VALUE:
		#_normal = _normal.linear_interpolate(val, acc).normalized()
		_normal = _normal.linear_interpolate(VectorLib.snap_to(val, VectorLib.POLY16), acc).normalized()


############
# Gravity methods
############

func verify_gravity_center_change(collision_info):
	
	if collision_info != null:
		var collider = collision_info.collider
		if collider.has_method("get_gravity_from_center") and _gravity_center != collider:
			change_center(collider)
			return collision_info
	return null


func get_gravity_data():
	if _gravity_center != null:
		return _gravity_center.get_gravity_from_center(position)
	return {gravity = Vector2(), normal = Vector2()}

func check_ground_reach(collision_info, changed_center):

	# Checking for small platform collisions...
	var on_small_platform = false
	if changed_center == null and collision_info != null:
		Console.l("Collision_normal", collision_info.normal)
		Console.l("my_normal", _normal)
		if _normal.dot(collision_info.normal) > 0.1:
			on_small_platform = true
			Console.l("collided", "COLLIDED!")

	if on_small_platform or (collision_info != null and (_falling or changed_center != null ) ):

		_altitude_velocity_scalar = 0
		_falling = false
		_attempting_jump = false
		reached_ground(_gravity_center)
		if not _moving:
			_target_move_velocity_scalar = 0
		return true
	return false

func adjust_normal_towards(new_normal, gravity_center_collision_data):
	var updated_normal = false
	var _prev_normal = new_normal

	if gravity_center_collision_data != null:
		new_normal = get_gravity_data().normal

	if _target_normal != null:
		# If _normal is close enough (less than 45 degrees) to target
		if _target_normal.dot(_normal) > 0.5:
			# Interpolate towards target one last time and remove target.
			interpolate_normal_towards(TOWARDS_TARGET)
			_target_normal = null
			if _rolling: end_rolling()
			set_rolling(false)
		else:
			# If not, use tangent to move in the direction defined by target_normal
			interpolate_normal_towards(TOWARDS_TANGENT)
			
		updated_normal = true
	elif new_normal != Vector2():
		# If there is new normal, and gravity center was swapped, and the angle between the new normal and the old
		# is greater than 45 or so degrees, then new orientation of movement
		var normal_dot = new_normal.dot(_normal)
		if gravity_center_collision_data != null and normal_dot <= 0.7:
			# New normal target
			_target_normal = new_normal

			var collision_normal = gravity_center_collision_data.normal
			var move_direction = (-_prev_normal).tangent() * _facing * _invertor
			var new_direction = (-new_normal).tangent() * _facing * _invertor
			var distance_old_move = (collision_normal - move_direction).length_squared() + (_prev_normal - move_direction).length_squared()
			var distance_new_move = (collision_normal - new_direction).length_squared() + (_prev_normal - new_direction).length_squared()
			var decisive_dot = collision_normal.dot(_prev_normal)
	
			if decisive_dot < -0.9 or decisive_dot >= -0.9 and distance_old_move < distance_new_move:
				# We are rotating the normal "the long way" because visually, it makes more sense

				# If character is not moving, invertors are not updated, so inversion must be found from criteria
				#if _target_move_velocity_scalar == 0 and inversion_criteria_met(_normal): 
				#	_invertor = INV_INVERTED
				#elif _target_move_velocity_scalar == 0:
				#	_invertor = INV_NORMAL

				#invert logic
				_target_normal_direction = _facing * _invertor
				_invertor *=  -1
				_target_move_velocity_scalar *= -1
				_move_velocity_scalar *= -1
				change_sprite_direction(_facing * _invertor)


			else:
				# Simple, if negative then we are moving counter closkwise, if positive, clockwise
				_target_normal_direction = VectorLib.vector_orientation(_normal, _target_normal)
				
				
			interpolate_normal_towards(TOWARDS_TANGENT)
			set_rolling(true)
			start_rolling()

		else:
			# if not, we are close enough to the new normal to go the old fashioned way
			interpolate_normal_towards(TOWARDS_NEW_VALUE, new_normal)
			if _rolling: end_rolling()
			set_rolling(false)
			
		updated_normal = true

	if updated_normal:
		$ground_raycast.set_normal(new_normal)
		update_normal() 

############
# Virtual methods
############

func inversion_criteria_met(vect):

	return vect.dot(Vector2(0, -1)) < -0.4
	#return vect.dot(Vector2(0, -1)) < 0


func on_gravity_center_changed():
	pass

func change_sprite_direction(direction):
	pass

func set_sprite_rotation(angle):
	pass

func _process_behavior(delta):
	pass

func reached_peak_height():
	pass
	
func reached_ground(ground_object):
	pass
	
func start_rolling():
	pass
	
func end_rolling():
	pass

func entered_water(center):
	pass

func left_water():
	pass

############
# Physics process method
############


func _physics_process(delta):

	fix_parents()

	if is_on_gravity_center():
		_gravity_physics(delta)
	elif is_on_water_center():
		_water_physics(delta)
	else:
		if space_velocity.length_squared() > 0.01:
			var motion = space_velocity * delta
			_last_velocity = space_velocity
			

			var collision_data = move_and_collide(motion)
			var changed_center = verify_gravity_center_change(collision_data)
			
			if check_ground_reach(collision_data, changed_center):
				adjust_normal_towards(get_gravity_data().normal, changed_center)
		
		else:
			_last_velocity = Vector2()



func _gravity_physics(delta):
	var collision_normal = null
	_on_ground = false
	if not _attempting_jump:
	
		var ground_cast_result = $ground_raycast.cast_ground(Glb.get_collision_layer_int(["Platform"]))
		
		var gcenter_id = -1 if _gravity_center == null else _gravity_center.get_instance_id()
		var on_small_platform = not ground_cast_result.empty() and ground_cast_result.collider_id != gcenter_id and _normal.dot(ground_cast_result.normal) > 0.1
		var valid_raycast = not ground_cast_result.empty() and ground_cast_result.collider_id == gcenter_id


		if valid_raycast or on_small_platform:
			collision_normal = ground_cast_result.normal
			_on_ground = true
			_falling = false
			reached_ground(_gravity_center)
			if not _moving:
				_target_move_velocity_scalar = 0

	_process_behavior(delta)

	var gravity_data = get_gravity_data()
	var gravity = gravity_data.gravity
	var normal = gravity_data.normal

	var move_velocity = Vector2()
	var altitude_velocity = Vector2()
	var environment_velocity = Vector2()


	_move_velocity_scalar = lerp(_move_velocity_scalar, _target_move_velocity_scalar, 0.1)
	# We use the right perpendicular to the normal because the direction is in _move_velocity_scalar
	
	move_velocity = (-normal).tangent() * _move_velocity_scalar
		
		
	if not _on_ground and not _rolling:
		
		_prev_altitude_velocity_scalar = _altitude_velocity_scalar
		_altitude_velocity_scalar += _gravity_scalar * delta
		altitude_velocity = gravity * -_altitude_velocity_scalar
	
		if _prev_altitude_velocity_scalar >= 0 and _altitude_velocity_scalar <= 0:
			reached_peak_height()
			_falling = true
			_attempting_jump = false


	var velocity = move_velocity + altitude_velocity
	var collision_info = null
	if velocity.length_squared() > 0.01:
		_last_velocity = velocity
		var motion = velocity * delta

		# Fixing movement to create boundaries illusion

		var result = $ground_raycast.cast_movement(motion, Glb.get_collision_layer_int(["Platform"]))

		var gcenter_id = -1 if _gravity_center == null else _gravity_center.get_instance_id()
		var valid_raycast = not result.rest.empty() and result.rest.collider_id == gcenter_id

		if valid_raycast and result.rest.normal.dot(_normal) < 0.7:
			motion = motion.slide(result.rest.normal)
		elif valid_raycast and result.motion.size() > 0:
			if result.motion[0] > 0:
				motion *= result.motion[0]
			
		collision_info = move_and_collide(motion)
	else:
		_last_velocity = Vector2()

	var changed_center = false
	changed_center = verify_gravity_center_change(collision_info)

	check_ground_reach(collision_info, changed_center)
	adjust_normal_towards(normal, changed_center)

	if not _on_ground:
		_loosed_ground_delta += delta
	else:
		_loosed_ground_delta = 0
		



func _water_physics(delta):
	
	var swin_velocity_squared = swim_velocity.length_squared()
	if swin_velocity_squared > 0.01:
		var squared_resistance = _water_center.get_water_resistance_squared_scalar()
		var resistance = _water_center.get_water_resistance_scalar() * _water_resistance_multiplier
	

		swim_velocity += swim_velocity.normalized() * resistance * delta
		
		_last_velocity = swim_velocity
		var collision_data = move_and_collide(swim_velocity * delta)



	_process_behavior(delta)

	if _target_normal != null:
		if _normal.dot(_target_normal) > 0:
			interpolate_normal_towards(TOWARDS_TARGET)
		else:
			if _normal.tangent().dot(_target_normal) > (-_normal.tangent()).dot(_target_normal):
				_target_normal_direction = 1
			else:
				_target_normal_direction = -1
			interpolate_normal_towards(TOWARDS_TANGENT)
		update_normal()

	if _swim_impulse_delta > 0:
		_swim_impulse_delta -= delta
	else:
		_swim_impulse_delta = 0
	
	if _water_center != null and not _water_center.overlaps_body(self):
		_water_center.on_body_out(self, global_position, _last_velocity)

		change_center(null)
		

	