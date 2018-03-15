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

#const SWIM_STROKE_DURATION = 0.5
const SWIM_STROKE_DURATION = 0.6

#const ON_GROUNDTHRESHOLD = 0.025
const ON_GROUNDTHRESHOLD = 0.05

enum ControlMode {ROTATION, INVERSION}


######## Physics/Movement #########
var _altitude_velocity_scalar = 0.0

var _move_velocity_scalar = 0.0
var _target_move_velocity_scalar = 0.0

var _prev_altitude_velocity_scalar = 0

var _target_swim_velocity_scalar = null
var _swim_velocity_scalar = 0.0

var _last_velocity = Vector2()
var _last_velocity_normalized = Vector2()
var swim_velocity = Vector2()
var space_velocity = Vector2()

var move_speed_reducer = 0

######## Slope related #########

var _slope_stop_min_vel = 0
var _max_bounce = 80
var _max_angle = 0.795398


######## Gravity #########

var _gravity_center = null
var _gravity_scalar = 0.0

######## Water #########

var _water_center = null

var swim_tilt_velocity = Vector2()
var swim_tilt_to_45_time = 0.0

var swim_stroke_step = 0.0

######## Collision Related #########
var colliders = []
var collision_normal = null

######## Open Space #########

var _open_space = null

######## Normal #########

var _normal = Vector2(0, -1)
var _start_normal = Vector2()
var _target_normal_direction = 0
var _target_normal = null
var normal_t = 0

######## Misc #########
var _facing = FACING_RIGHT
# Invert controls!
var _invertor = FACING_RIGHT

######## Deltas #########
var _loosed_ground_delta = 0
var step_delta = 0
var step_duration = 0
var peak_jump_time
var jump_delta = 0
var mid_air_delta = null

######## States #########
var _on_ground = false
var _falling = true
var _moving = false
var _attempting_jump = false
var _rolling = false
var _step = false
var halt_physics = false
var _normal_update = false

######## Configuration #########
var _control_mode = ROTATION


############
# Init methods
############

func _ready():

	var new_parent = get_parent()

	if new_parent.has_method("is_open_space"):
		_open_space = new_parent
	elif new_parent.has_method("get_gravity_from_center"):
		_gravity_center = new_parent

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

func set_peak_jump_time(time):
	peak_jump_time = time

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

func set_step_duration(duration):
	step_duration = duration

func get_gravity_center():
	return _gravity_center

func set_gravity_center(center):
	if center != null:
		
		#if _gravity_center != null:
		#	_gravity_center.remove_collision_exception_with(self)
		
		_gravity_center = center
		var rot = global_rotation
		var pos = global_position

		get_parent().remove_child(self)
		_gravity_center.add_child(self)
		#_gravity_center.add_collision_exception_with(self)
		_gravity_center.move_child(self, _gravity_center.get_tree_pos())
		global_rotation = rot
		global_position = pos
		
		entered_gravity_platform(_gravity_center)
	elif _gravity_center != null:
		#_gravity_center.remove_collision_exception_with(self)
		_gravity_center = null
		#left_gravity_platform()

func get_water_center():
	return _water_center

func set_water_center(center):
	if center != null:
		restore_speed()
		var resistance = abs(center.get_water_resistance_scalar())
		var vel =  clamp(_last_velocity.length(), 90, resistance)

		_water_center = center
		water_arrival_normal = null
		
		var pos = global_position
		get_parent().remove_child(self)
		_water_center.add_child(self)

		_water_center.move_child(self, _water_center.get_tree_pos())

		global_position = pos
		if not is_on_ground():
			swim_velocity = -position.normalized() * vel

	
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

func change_center(new_center):
	
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

func set_normal(n):
	_normal = n
	_normal_update = true

func get_target_normal():
	return _target_normal

func set_target_normal(tn):
	_target_normal = tn

func set_gravity_scalar(g):
	_gravity_scalar = g


func get_gravity_scalar():
	return _gravity_scalar

func get_last_velocity():
	return _last_velocity

func get_last_velocity_normalized():
	return _last_velocity_normalized

func set_last_velocity(v):
	_last_velocity = v
	_last_velocity_normalized = v.normalized()

func is_falling():
	return _falling
	
func is_on_ground():
	return _on_ground or _loosed_ground_delta < ON_GROUNDTHRESHOLD 
	
func is_room_env():
	return _gravity_center != null and _gravity_center.has_method("is_room")
	
func is_moving():
	return _moving

func is_rolling():
	return _rolling

func is_idle():
	return not _rolling and not _moving and not _falling and is_on_ground()

func set_rolling(value):
	_rolling = value
	if _rolling:
		start_rolling()
	else:
		end_rolling()

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
	jump_delta = peak_jump_time

	_loosed_ground_delta = ON_GROUNDTHRESHOLD 



func move(velocity, new_facing=null):
	
	if new_facing != null:
		set_facing(new_facing)
	#_target_move_velocity_scalar = velocity * _facing * _invertor
	
	if not _moving:
		add_step_impulse(velocity)
		_moving = true

	_target_move_velocity_scalar = abs(_target_move_velocity_scalar) * _facing * _invertor
	_move_velocity_scalar = abs(_move_velocity_scalar) * _facing * _invertor

func add_step_impulse(step_velocity):
	step_delta = step_duration

	#_target_move_velocity_scalar= step_velocity
	_target_move_velocity_scalar = step_velocity * _facing * _invertor

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



func add_swim_impulse(swim_impulse_scalar):

	if _water_center != null:

		swim_stroke_step = 0.0
		_target_swim_velocity_scalar  = swim_impulse_scalar
		_water_center.child_movement(position)

func increase_water_resistance():
	if _target_swim_velocity_scalar != null:
		var diff = _target_swim_velocity_scalar - _swim_velocity_scalar
		if diff > 0:
			var done = _swim_velocity_scalar / _target_swim_velocity_scalar
			_target_swim_velocity_scalar -= diff * lerp(0, 1, Glb.Smooth.water_resistance(done))

############
# Helper methods
############

func start_normal_interpolation(new_normal):
	normal_t = 0
	_target_normal = new_normal
	_start_normal = _normal


func transform_to_local(global_vec):
	var trans = Transform2D(-_normal.tangent(), -_normal, Vector2())
	return trans.xform_inv(global_vec)


############
# Gravity methods
############

func verify_center_change(delta):
	
	# Translate to original coordinates to be able to set correct position into raycaster, as the
	# raycaster exist in the local coordinate system of the Character and not the global one
	#var direction = transform_to_local(get_last_velocity_normalized()) * 25

	var direction = transform_to_local(get_last_velocity() * 4 * delta)
	var res = {}
	
	if not is_rolling():
		res = $ground_raycast.cast_ray_ahead(direction, Glb.get_collision_layer_int(["Platform"]))

	if not res.empty() and not is_room_env() and res.collider != _gravity_center:
		# there should be a way to mark this as a before collision center change
		colliders.push_back(res)


	var result = {
		changed_center = false,
		collision_info = null,
		is_headcast = false
	}


	if not verify_water_center(false):
		var gcenter_change = verify_gravity_center_change()
		if gcenter_change != null:
			result.collision_info = gcenter_change 
			if gcenter_change == res:
				result.is_headcast = true
		result.changed_center = gcenter_change != null

	return result


func verify_gravity_center_change():

	var i = 0
	var result = null
	while i < colliders.size() and result == null:
		if get_parent() != colliders[i].collider:
			result = colliders[i]
		i += 1
	if result != null:
		change_center(result.collider)
	return result


func get_gravity_data():
	if _gravity_center != null:
		return _gravity_center.get_gravity_from_center(position)
	return {gravity = Vector2(), normal = Vector2()}

func add_collision(c):
	if c != null:
		colliders.push_back({collider = c.collider, normal = c.normal})

func add_slide_collisions():
	var i = 0
	while i < get_slide_count():
		var collision = get_slide_collision(i)
		if collision.collider.has_method("get_gravity_from_center"):
			colliders.push_back({collider = collision.collider, normal = collision.normal})
		i += 1


func check_ground_reach(center_verification):

	# Checking for small platform collisions...

	var collided = center_verification.collision_info != null

	if   collided and (_falling or center_verification.changed_center ) :
		_prev_altitude_velocity_scalar = 0
		_altitude_velocity_scalar = 0
		_falling = false
		_attempting_jump = false
		reached_ground(_gravity_center)
		if not _moving:
			_target_move_velocity_scalar = 0
		return true
	return false


var time = 0
func adjust_normal_towards(new_normal, center_verification, delta):
	var updated_normal = false
	var _prev_normal = new_normal

	if center_verification.changed_center:
		new_normal = get_gravity_data().normal
		_target_normal = null


	if water_arrival_normal != null:
		set_normal(Glb.Smooth.radial_interpolate(_normal, water_arrival_normal, delta / 0.0625))

		if water_arrival_normal.dot(_normal) > 0.9:
			water_arrival_normal = null
		updated_normal = true
	elif _target_normal != null:
		time += delta
		normal_t += delta / 0.65

		set_normal(Glb.Smooth.directed_radial_interpolate(_start_normal, _target_normal, normal_t, _target_normal_direction))

		var dot = _normal.dot(_target_normal)
		if dot > 0.5:
			if is_rolling(): 
				set_rolling(false)

		if dot > 0.999 or normal_t >= 1:
			set_normal(_target_normal)
			_target_normal = null
			time = 0

		updated_normal = true
	elif new_normal != Vector2():
		
		# If there is new normal, and gravity center was swapped, and the angle between the new normal and the old
		# is greater than 45 or so degrees, then new orientation of movement
		var normal_dot = new_normal.dot(_normal)
		if center_verification.changed_center and normal_dot <= 0.5:
			# New normal target
			
			var collision_normal = new_normal
			if center_verification.collision_info != null:
				collision_normal = center_verification.collision_info.normal
				
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
				_target_normal_direction = Glb.VectorLib.vector_orientation(_normal, new_normal)
				
			start_normal_interpolation(new_normal)
			set_rolling(true)

		else:
			# if not, we are close enough to the new normal to go the old fashioned way
			set_normal(Glb.Smooth.radial_interpolate(_normal, new_normal, delta / 0.0625))
			if is_rolling(): 
				set_rolling(false)
			
		updated_normal = true

	if updated_normal:
		$ground_raycast.set_normal(new_normal)


############
# Water methods
############

func limit_water_movement_on_edges(inner_radius, velocity):
	var normalized_dist = clamp(position.length() /  inner_radius, 0.0, 1.0)

	var center_direction = position.normalized()
	var min_speed = 50
	min_speed *= min_speed


	if center_direction.dot(velocity) >= -0.1 and velocity.length_squared() < min_speed and normalized_dist > 0.5:
		return velocity.linear_interpolate(Vector2(), Glb.Smooth.water_resistance_on_edges(normalized_dist))
	return velocity


func verify_water_center(with_center=true):
	var water_cast_result = $water_raycast.cast_water(Glb.get_collision_layer_int(["WaterPlatform"]))
	
	if with_center:
		return not water_cast_result.empty() and water_cast_result.collider == _water_center
	elif not water_cast_result.empty() and not is_on_ground() and (_attempting_jump or _falling): 
		change_center(water_cast_result.collider)
		return true
	elif not water_cast_result.empty():
		slow_down()
	else:
		restore_speed()

	return false

var water_arrival_normal = null
func check_for_water_arrival(global_water_pos, radius):
	var direction = (global_water_pos - global_position).normalized()
	
	if direction.dot(get_last_velocity_normalized()) > 0 and not _on_ground:
		water_arrival_normal = direction


func failed_water_arrival():
	water_arrival_normal = null

############
# Virtual methods
############

func slow_down():
	pass

func restore_speed():
	pass

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

func little_physics_process(delta):
	pass
	
func reached_peak_height():
	pass
	
func reaching_peak():
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
		
	colliders.clear()
	if not halt_physics:
		if is_on_gravity_center():
			_gravity_physics(delta)
		elif is_on_water_center():
			_water_physics(delta)
		else:
			if space_velocity.length_squared() > 0.01:
				set_last_velocity(space_velocity)
				

			#var r = move_and_slide(_last_velocity, _normal, _slope_stop_min_vel, _max_bounce, _max_angle)
			var c = move_and_collide(_last_velocity * delta)
			
			add_collision(c)
			
			var center_verification = verify_center_change(delta)

			check_ground_reach(center_verification)
			if center_verification.changed_center:
				adjust_normal_towards(_normal, center_verification, delta)


	little_physics_process(delta)


	if _normal_update:
		# translating rotation from vector to node transform
		global_rotation = (-_normal).tangent().angle()
		
		normal_shift_notice(_normal, $ground_raycast.get_normal())
		_normal_update = false


func _gravity_physics(delta):
	
	var ground_cast_result
	
	_on_ground = false
	if not _attempting_jump:
		ground_cast_result = $ground_raycast.cast_ground(Glb.get_collision_layer_int(["Platform"]))
		
		if not ground_cast_result.empty() and ground_cast_result.collider_count > 0:
			colliders += ground_cast_result.gravity_centers
			
			collision_normal = ground_cast_result.normal
			_on_ground = true
			if _falling:
				reached_ground(_gravity_center)
			_falling = false

			_prev_altitude_velocity_scalar = 0
			_altitude_velocity_scalar = 0

			if not _moving:
				_target_move_velocity_scalar = 0
	
	
	_process_behavior(delta)

	var gravity_data = get_gravity_data()
	var gravity = gravity_data.gravity
	var normal = gravity_data.normal


	var move_velocity = Vector2()
	var altitude_velocity = Vector2()
	var environment_velocity = Vector2()

	if step_delta > 0:
		step_delta -= delta
	
	var step_t = 0
	if step_duration > 0:
		step_t = step_delta / step_duration
	
		_move_velocity_scalar = lerp(0, _target_move_velocity_scalar, Glb.Smooth.run_step(step_t))

	# this normal has the collision included, if on air it will be just the center's normal. Ideal for _tarteg_normal
	var move_norm = normal
	if collision_normal != null:
		
		# If indoors, just use the collision normal for the velocity, if not, use an average
		if (_gravity_center != null and _gravity_center.has_method("is_room")) or  not is_on_ground():
			move_norm = collision_normal
			move_velocity = (-move_norm).tangent().normalized() * _move_velocity_scalar
		else:

			move_norm = normal
			# We tilt the tangent a little bit towards the gravity to avoid the player from microfalling thanks to move_and_slide
			var tangent = 4*(-move_norm).tangent()
			if _move_velocity_scalar < 0:
				tangent *= -1
			move_velocity = (tangent + gravity).normalized() * abs(_move_velocity_scalar)

	else:
		move_velocity = (-normal).tangent().normalized() * _move_velocity_scalar
	

	
	if not is_on_ground() and not _rolling:
		move_norm = normal
		jump_delta -= delta

		_prev_altitude_velocity_scalar = _altitude_velocity_scalar
		_altitude_velocity_scalar += _gravity_scalar * delta
		if _altitude_velocity_scalar < -700:
			_altitude_velocity_scalar = -700

		altitude_velocity = gravity * -_altitude_velocity_scalar
	
		# This is just here just for animation improvement
		# 0.245 its the duration of the peak animation to reach the peak point
		if jump_delta < peak_jump_time - 0.245 and jump_delta > 0:
			reaching_peak()
			jump_delta = 0
		
		# This, on the other hand, is very important
		if _prev_altitude_velocity_scalar >= 0 and _altitude_velocity_scalar <= 0:
			reached_peak_height()
			_falling = true
			_attempting_jump = false

	var center_verification = null
	var velocity = move_velocity + altitude_velocity
	var collision_info = null
	
	############################################################################################################

	# Softening roll for gravity center change, using own gravity clossiness
	if mid_air_delta != null:
		velocity = Vector2()
		mid_air_delta -= delta
		_altitude_velocity_scalar = 0
		_target_move_velocity_scalar = 0
		_move_velocity_scalar = 0
		step_delta = 0
		jump_delta = 0
		if mid_air_delta <= 0:
			mid_air_delta = null
		else:
			velocity = gravity * 810 * mid_air_delta
	############################################################################################################

	
	if velocity.length_squared() > 0.01:
		set_last_velocity(velocity)
	else:
		set_last_velocity(Vector2())

	move_and_slide(velocity, normal, _slope_stop_min_vel, _max_bounce, _max_angle)
	
	add_slide_collisions()

	center_verification = verify_center_change(delta)

	############################################################################################################

	Console.add_log("velocity", velocity)
	Console.add_log("_altitude_velocity_scalar", _altitude_velocity_scalar)
	Console.add_log("_move_velocity_scalar", _move_velocity_scalar)
	# If about to roll, avoid head collision and stop all movement and change gravity center.
	if center_verification.changed_center and center_verification.is_headcast:

		_altitude_velocity_scalar = 0
		_target_move_velocity_scalar = 0
		_move_velocity_scalar = 0
		step_delta = 0
		jump_delta = 0
		mid_air_delta = 0.3
		if not is_on_ground():
			_falling = true
			_attempting_jump = false
	
	if center_verification.changed_center:
		Console.add_log("center_verification", center_verification)
	Console.add_log("center_verification.changed_center", center_verification.changed_center)

	############################################################################################################

	check_ground_reach(center_verification)

	# If on a room and not out there, use the constant normal
	if is_room_env():
		adjust_normal_towards(normal, center_verification, delta)
	else:
		adjust_normal_towards(move_norm, center_verification, delta)
	

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

	var swin_velocity_squared = swim_velocity.length_squared()
	var swim_tilt_velocity_squared = swim_tilt_velocity.length_squared()


	if swin_velocity_squared > 25:
		swim_velocity += swim_velocity.normalized() * resistance * delta
	

	
	if swim_tilt_velocity_squared > 8.25:# 6.25:
		swim_tilt_velocity += swim_tilt_velocity.normalized() * resistance * delta

	
	set_last_velocity(_water_center.report_body(self, swim_velocity + swim_tilt_velocity))
	
	
	if _last_velocity.length_squared() > 0.01:
		move_and_slide(_last_velocity, _normal, _slope_stop_min_vel, _max_bounce, _max_angle)
	else:
		set_last_velocity(Vector2())

	"""
	add_slide_collisions()
	var center_verification = verify_center_change(delta)
	if check_ground_reach(center_verification):
		adjust_normal_towards(_normal, center_verification, delta)
	"""

	_process_behavior(delta)

	# percentage from total lerp
	var percentage = swim_tilt_to_45_time / delta


	if _target_normal != null:
		set_normal(Glb.Smooth.radial_interpolate(_normal, _target_normal, 1 / percentage))



	if not verify_water_center():
		change_center(_open_space)

		


