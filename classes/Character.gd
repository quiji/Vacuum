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

const SWIM_STROKE_DURATION = 0.5

enum ControlMode {ROTATION, INVERSION}


######## Physics/Movement #########
var _altitude_velocity_scalar = 0.0

var _move_velocity_scalar = 0.0
var _target_move_velocity_scalar = 0.0

var _prev_altitude_velocity_scalar = 0

var _target_swim_velocity_scalar = null
var _swim_velocity_scalar = 0.0

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

var swim_tilt_velocity = Vector2()
var swim_tilt_to_45_time = 0.0

var swim_stroke_step = 0.0

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

######## Deltas #########
var _loosed_ground_delta = 0


######## States #########
var _on_ground = false
var _falling = true
var _moving = false
var _attempting_jump = false
var _rolling = false
var halt_physics = false

######## Configuration #########
var _control_mode = ROTATION


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


	Console.add_log(self, "_falling")
	Console.add_log(self, "_on_ground")
	Console.add_log(self, "_rolling")

	Console.add_log(self, "_gravity_center")
	Console.add_log(self, "_water_center")



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
		_gravity_center.move_child(self, _gravity_center.get_tree_pos())
		global_rotation = rot
		global_position = pos
		
		entered_gravity_platform(_gravity_center)
	elif _gravity_center != null:
		_gravity_center.remove_collision_exception_with(self)
		_gravity_center = null
		#left_gravity_platform()

func get_water_center():
	return _water_center

func set_water_center(center):
	if center != null:
		var resistance = abs(center.get_water_resistance_scalar())
		var dir = (center.global_position - global_position).normalized() 
		var vel =  clamp(_last_velocity.length(), 90, resistance * 1.5)

		increase_water_resistance()

		swim_velocity = (_last_velocity.normalized() + dir * 1.4).normalized() * vel
		_water_center = center
		
		var pos = global_position
		get_parent().remove_child(self)
		_water_center.add_child(self)

		_water_center.move_child(self, _water_center.get_tree_pos())

		global_position = pos
		entered_water(_water_center)
	elif _water_center != null:

		_water_center = null
		left_water()


func set_open_space_center(center):
	space_velocity = _last_velocity
	if center != null:

		var pos = global_position
		get_parent().remove_child(self)
		center.add_child(self)
		center.move_child(self, center.get_tree_pos())
		global_position = pos
		entered_space(center)

		
func set_space_velocity(v):
	space_velocity = v

var was_water_center = false
func change_center(new_center):
	
	Console.add_log("new_center", new_center.name)
	
	if new_center == null:
		pass
	elif new_center.has_method("get_gravity_from_center"):

		set_gravity_center(new_center)
		set_water_center(null)
		set_open_space_center(null)
	elif new_center.has_method("get_water_resistance_scalar"):
		set_water_center(new_center)
		set_gravity_center(null)
		set_open_space_center(null)

	else:
		set_gravity_center(null)
		set_water_center(null)
		set_open_space_center(new_center)


func get_normal():
	return _normal

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
	


func tilt(direction, tilt_to_45_time, tilt_speed):
	_target_normal = direction
	
	var til_speed_factor = 1
	var normal_dot = _normal.dot(_target_normal)
	if normal_dot > 0:
		til_speed_factor = clamp(1 - normal_dot, 0.4, 1)

	swim_tilt_velocity = (_normal + _target_normal).normalized() * tilt_speed * til_speed_factor
	swim_tilt_to_45_time = tilt_to_45_time 
	
func stop_tilt():
	_target_normal = null
	#swim_tilt_velocity = Vector2()

func update_normal():
	global_rotation = (-_normal).angle() - PI/2

	normal_shift_notice(_normal, $ground_raycast.get_normal())


var record_pos = Vector2()
func add_swim_impulse(swim_impulse_scalar):

	if _water_center != null:
		if started_stroke:
			swim_stroke_step = 0.0
			_target_swim_velocity_scalar  = swim_impulse_scalar
			started_stroke = false
		else:
			swim_stroke_step = 0.4
			_target_swim_velocity_scalar  = swim_impulse_scalar * 0.5
		record_pos = position
		_water_center.child_movement(position)

func increase_water_resistance():
	if _target_swim_velocity_scalar != null:
		var diff = _target_swim_velocity_scalar - _swim_velocity_scalar
		if diff > 0:
			var done = _swim_velocity_scalar / _target_swim_velocity_scalar
			_target_swim_velocity_scalar -= diff * 0.6 *(1 - done)

	started_stroke = false


var started_stroke = false
func decrease_water_resistance():
	started_stroke = true

############
# Helper methods
############


func interpolate_normal_towards(inter_type, val=null, acc=0.1):
	
	if inter_type == TOWARDS_TANGENT:
		_normal = _normal.linear_interpolate(Glb.VectorLib.snap_to(_normal.tangent(), Glb.VectorLib.POLY16) * _target_normal_direction, acc).normalized()
	elif inter_type == TOWARDS_TARGET:
		_normal = _normal.linear_interpolate(Glb.VectorLib.snap_to(_target_normal, Glb.VectorLib.POLY16), acc).normalized()
	elif inter_type == TOWARDS_NEW_VALUE:
		_normal = _normal.linear_interpolate(Glb.VectorLib.snap_to(val, Glb.VectorLib.POLY16), acc).normalized()


############
# Gravity methods
############

func verify_gravity_center_change(collision_info):
	
	if verify_water_center(false):
		return null

	if collision_info != null:
		var collider = collision_info.collider
		if  collider.has_method("get_gravity_from_center") and get_parent() != collider:
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
		Console.add_log("Collision_normal", collision_info.normal)
		Console.add_log("my_normal", _normal)
		if _normal.dot(collision_info.normal) > 0.1:
			on_small_platform = true
			Console.add_log("collided", "COLLIDED!")

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
				_target_normal_direction = Glb.VectorLib.vector_orientation(_normal, _target_normal)
				
				
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
# Water methods
############

func limit_water_movement_on_edges(inner_radius, velocity):
	var normalized_dist = clamp(position.length_squared() / (inner_radius * inner_radius), 0.0, 1.0)

	var center_direction = position.normalized()
	var min_speed = 50
	var min_tilt_speed = 14
	min_speed *= min_speed
	min_tilt_speed *= min_tilt_speed

	if center_direction.dot(velocity) >= -0.1 and velocity.length_squared() < min_speed and normalized_dist > 0.5:
		return velocity.linear_interpolate(Vector2(), Glb.Smooth.water_resistance_on_edges(normalized_dist))
	return velocity


func verify_water_center(with_center=true):
	var water_cast_result = $water_raycast.cast_water(Glb.get_collision_layer_int(["WaterPlatform"]))
	
	if with_center:
		return not water_cast_result.empty() and water_cast_result.collider == _water_center
	elif not water_cast_result.empty(): 
		change_center(water_cast_result.collider)
		return true
	return false



############
# Virtual methods
############

func normal_shift_notice(normal, target_normal):
	pass

func inversion_criteria_met(vect):

	return vect.dot(Vector2(0, -1)) < -0.4
	#return vect.dot(Vector2(0, -1)) < 0

func change_sprite_direction(direction):
	pass

func set_sprite_rotation(angle):
	pass

func _process_behavior(delta):
	pass

func little_physics_proces(delta):
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

func entered_space(center):
	pass
	
func entered_gravity_platform(center):
	pass

func left_water():
	pass

############
# Physics process method
############


func _physics_process(delta):

	if not halt_physics:
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

	little_physics_proces(delta)



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

	if _gravity_center != null:
		check_ground_reach(collision_info, changed_center)
		adjust_normal_towards(normal, changed_center)

	if not _on_ground:
		_loosed_ground_delta += delta
	else:
		_loosed_ground_delta = 0
		



func _water_physics(delta):
	
	
	var resistance = _water_center.get_water_resistance_scalar()


	if _target_swim_velocity_scalar != null:
		swim_stroke_step += delta / SWIM_STROKE_DURATION
		_swim_velocity_scalar = lerp(0, _target_swim_velocity_scalar, Glb.Smooth.swim_stroke(swim_stroke_step))
		swim_velocity = (swim_velocity * 0.8 + _normal * _swim_velocity_scalar).clamped(_target_swim_velocity_scalar * 1.02)
		if swim_stroke_step > 1:
			_target_swim_velocity_scalar = null
			Console.add_log("record", (record_pos - position).length())

	var swin_velocity_squared = swim_velocity.length_squared()
	var swim_tilt_velocity_squared = swim_tilt_velocity.length_squared()


	if swin_velocity_squared > 25:
		swim_velocity += swim_velocity.normalized() * resistance * delta

	
	if swim_tilt_velocity_squared > 8.25:# 6.25:
		swim_tilt_velocity += swim_tilt_velocity.normalized() * resistance * delta

	
	_last_velocity = _water_center.report_body(self, swim_velocity + swim_tilt_velocity)
	move_and_slide(_last_velocity, _normal, _slope_stop_min_vel, _max_bounce, _max_angle)

	_process_behavior(delta)

	# percentage from total lerp
	var percentage = swim_tilt_to_45_time / delta


	if _target_normal != null:
		if _normal.dot(_target_normal) > 0:
			interpolate_normal_towards(TOWARDS_TARGET, null, 1 / percentage)
		else:
			if _normal.tangent().dot(_target_normal) > (-_normal.tangent()).dot(_target_normal):
				_target_normal_direction = 1
			else:
				_target_normal_direction = -1
			interpolate_normal_towards(TOWARDS_TANGENT, null, 1 / percentage)
		update_normal()


	if not verify_water_center():
		change_center(_open_space)

		


