extends "res://classes/Character.gd"

const CameraMan = preload("res://addons/quijipixel.cameraman/CameraMan.gd")

######## Const Stats #########
var slope_stop_min_velocity = 5.0
var run_velocity = 100.0
var midair_move_velocity = 40.0
var max_x_distance_a_jump = 50.0
var max_x_distance_b_jump = 70.0
var jump_peak_height = 95.5

var smash_jump_impulse_scalar = 30.0
var swim_impulse_scalar = 190.5
var water_tilt_impulse_scalar = 35.0
var time_to_45_tilt_rotation = 0.4

######## Calculated Stats #########
var jump_initial_velocity_scalar = 0.0
var time_to_peak_of_jump = 0

var highgest_gravity_scalar = 0.0
var lowest_gravity_scalar = 0.0
var fall_gravity_scalar = 0.0


######## States #########
var smash_jumping = false
var smash_jump_start_point


######## Control schemes #########
var camera_rotation = 0

######## Backups #########
var old_sprite_pos = null
var old_shape_pos = null

func _ready():
	._ready()

	
	time_to_peak_of_jump = max_x_distance_a_jump / run_velocity
	jump_initial_velocity_scalar = 2*jump_peak_height / time_to_peak_of_jump

	fall_gravity_scalar = -2*jump_peak_height* (run_velocity*run_velocity) / (max_x_distance_b_jump*max_x_distance_b_jump)
	lowest_gravity_scalar = -2*jump_peak_height* (run_velocity*run_velocity) / (max_x_distance_a_jump*max_x_distance_a_jump)
	highgest_gravity_scalar = lowest_gravity_scalar * 6
	
	set_gravity_scalar(lowest_gravity_scalar)
	
	# Maybe this goes in the platform? we can play with platforms with different values
	set_slope_stop_min_vel(slope_stop_min_velocity)

	old_sprite_pos = $sprite.position
	old_shape_pos = $collision.position
	
	$sprite.connect("react", self, "_on_animation_reaction")


############
# Configuration methods
############

func establish_angle_from_camera():
	var cam = Glb.get_current_camera_man()
	camera_rotation = 0
	if cam != null:
		camera_rotation = cam.get_current_normal().angle() + PI/2

func rotate_to_camera_normal(v):
	if is_control_mode(ROTATION):
		return v.rotated(camera_rotation)
	return v

func make_camera_look(dir):
	var cam = Glb.get_current_camera_man()
	
	if cam != null:
		cam.look_direction(self, dir)

func restore_camera_look():
	var cam = Glb.get_current_camera_man()
	
	if cam != null:
		cam.look_direction(self, CameraMan.LOOK_CENTER)

	
############
# Callback methods
############


func _on_animation_reaction(action):

	match action:
		Glb.REACT_STEP:
			pass
		Glb.REACT_SWIMSTROKE: 
			add_swim_impulse(swim_impulse_scalar)
		Glb.REACT_ENDSWIMSTROKE: 
			$sprite.allow_interruption()

############
# Helper methods
############

var target_pivot = null
var start_pivot = null
var pivot_t = 0
var center_direction = null
func transition_pivot(from, to):
	halt_physics = true
	target_pivot = to
	start_pivot = from
	pivot_t = 0


############
# Overriden methods
############


func normal_shift_notice(new_normal, target_normal):
	var cam = Glb.get_current_camera_man()

	if is_on_water_center() or is_on_space():
		cam.normal_shift(self, new_normal, target_normal, CameraMan.NO_ROTATION)
	elif is_on_gravity_center():
		cam.normal_shift(self, new_normal, target_normal, CameraMan.FOLLOW_POLY4)


func change_sprite_direction(direction):
	if direction == FACING_LEFT:
		$sprite.set_flip_h(true)
	else:
		$sprite.set_flip_h(false)

func reached_peak_height():
	set_gravity_scalar(fall_gravity_scalar)
	if not $sprite.is_playing("EndRoll") and not $sprite.is_playing("StartRoll"):
		$sprite.play("Peak")

func reached_ground(ground_object):
	
	if smash_jumping:
		smash_jumping = false
		if ground_object != null and ground_object.has_method("apply_impulse"):
			var distance_squared = (position - smash_jump_start_point).length_squared()
			var impulse = -_normal * smash_jump_impulse_scalar * distance_squared / jump_peak_height * jump_peak_height
			ground_object.apply_impulse(position, impulse)

	set_gravity_scalar(lowest_gravity_scalar)
	
	if not $sprite.is_playing("EndRoll"):
		if is_moving():
			$sprite.play("Run")
		elif not is_moving() and not $sprite.is_looking():
			$sprite.play("Idle")


func start_rolling():
	$sprite.play("StartRoll")

func end_rolling():
	$sprite.play("EndRoll")

func entered_space(center):
	Glb.get_current_camera_man().setup_camera(self, CameraMan.SETUP_CENTER)
	
func entered_gravity_platform(center):
	Glb.get_current_camera_man().setup_camera(self, CameraMan.SETUP_UP)

func entered_water(water_bubble):
	$sprite.play("WaterIdle")


	center_direction = -position.normalized()
	transition_pivot(0, 18)

	#Glb.get_current_camera_man().setup_camera(self, CameraMan.SETUP_CENTER, get_water_center())


func left_water():
	transition_pivot(18, 0)


func little_physics_process(delta):

	if target_pivot != null:
		var entering_water = target_pivot - start_pivot > 0
		pivot_t += delta / 0.4
		#pivot_t += delta / 2.0
		
		var current_pivot =  0 
		var current_position = 0
		if entering_water:
			if not is_on_ground():
				interpolate_normal_towards(TOWARDS_NEW_VALUE, center_direction, Glb.Smooth.water_entrance_rotation(pivot_t))
				update_normal()
			current_pivot = Glb.Smooth.linear_interp(start_pivot, target_pivot, Glb.Smooth.water_in_pivot(pivot_t))
			current_position = Glb.Smooth.linear_interp(start_pivot, target_pivot, Glb.Smooth.water_in(pivot_t))
		else:
			current_pivot = Glb.Smooth.linear_interp(start_pivot, target_pivot, Glb.Smooth.water_out(pivot_t))
			current_pivot = Glb.Smooth.linear_interp(start_pivot, target_pivot, Glb.Smooth.water_in_pivot(pivot_t))
			
			
		$sprite.position = old_sprite_pos + Vector2(0, 1) * current_pivot
		$collision.position = old_shape_pos + Vector2(0, 1) * current_pivot
		
		if entering_water:
			if not is_on_ground():
				global_position += center_direction.normalized() * current_pivot * 7 * delta
			else:
				global_position += (center_direction + _normal).normalized() * current_pivot * 6 * delta
		else:
			global_position += _last_velocity.normalized() * current_pivot * 1 * delta
		if pivot_t > 1:
			target_pivot = null
			halt_physics = false
			pivot_t = 0
			if entering_water:
				Glb.get_current_camera_man().setup_camera(self, CameraMan.SETUP_CENTER, get_water_center())



func _process_behavior(delta):

	if is_on_gravity_center():
		_gravity_behavior(delta)
	elif is_on_water_center():
		_water_behavior(delta)

func _gravity_behavior(delta):
	
	if is_rolling():
		
		move(run_velocity)
		
	elif Input.is_action_just_pressed("ui_left"):
		
		if is_on_ground():
			$sprite.play("Run")
			move(run_velocity, FACING_LEFT)
		else:
			move(midair_move_velocity, FACING_LEFT)

	elif  Input.is_action_pressed("ui_left") and is_on_ground():
		
		move(run_velocity, FACING_LEFT)
		
		
	elif Input.is_action_just_released("ui_left"):
		
		stop(not is_on_ground())
		
		if is_on_ground():
			$sprite.play("Idle")
			
	elif Input.is_action_just_pressed("ui_right"):
		

		if is_on_ground():
			$sprite.play("Run")
			move(run_velocity, FACING_RIGHT)
		else:
			move(midair_move_velocity, FACING_RIGHT)
			
	elif  Input.is_action_pressed("ui_right") and is_on_ground():
		
		move(run_velocity, FACING_RIGHT)
		
	elif Input.is_action_just_released("ui_right"):

		stop(not is_on_ground())

		if is_on_ground():
			$sprite.play("Idle")


	elif not Input.is_action_pressed("ui_right") and not Input.is_action_pressed("ui_left"):
		stop()

	if Input.is_action_just_pressed("jump") and is_on_ground():
		
		$sprite.play("Jump")

		
		set_gravity_scalar(lowest_gravity_scalar)
		jump(jump_initial_velocity_scalar)
		
	elif Input.is_action_just_released("jump") and not is_falling() and not is_on_ground():
		
		set_gravity_scalar(highgest_gravity_scalar)


	if Input.is_action_just_pressed("ui_down") and not is_on_ground():
		stop_in_air()
		smash_jumping = true
		smash_jump_start_point = position
		set_gravity_scalar(highgest_gravity_scalar * 3)


	if Input.is_action_just_pressed("ui_up") and is_idle():
		$sprite.play("LookUp")
		make_camera_look(CameraMan.LOOK_UP)

	elif Input.is_action_just_released("ui_up") and $sprite.is_looking():
		$sprite.play("LookUp", true)
		restore_camera_look()

	if Input.is_action_just_pressed("ui_down") and is_idle():
		$sprite.play("LookDown")
		make_camera_look(CameraMan.LOOK_DOWN)

	elif Input.is_action_just_released("ui_down") and $sprite.is_looking():
		$sprite.play("LookDown", true)
		restore_camera_look()




func _water_behavior(delta):
	
	var left_p = Input.is_action_pressed("ui_left")
	var right_p = Input.is_action_pressed("ui_right")
	var up_p = Input.is_action_pressed("ui_up")
	var down_p = Input.is_action_pressed("ui_down")
	
	var left_jr = Input.is_action_just_released("ui_left")
	var right_jr = Input.is_action_just_released("ui_right")
	var up_jr = Input.is_action_just_released("ui_up")
	var down_jr = Input.is_action_just_released("ui_down")

	if is_control_mode(ROTATION):
		establish_angle_from_camera()

	if left_p and up_p:
		tilt( rotate_to_camera_normal(Vector2(-0.707107, -0.707107)), time_to_45_tilt_rotation, water_tilt_impulse_scalar )
	elif left_p and down_p:
		tilt( rotate_to_camera_normal(Vector2(-0.707107, 0.707107)), time_to_45_tilt_rotation, water_tilt_impulse_scalar )
	elif right_p and up_p:
		tilt( rotate_to_camera_normal(Vector2(0.707107, -0.707107)), time_to_45_tilt_rotation, water_tilt_impulse_scalar )
	elif right_p and down_p:
		tilt( rotate_to_camera_normal(Vector2(0.707107, 0.707107)), time_to_45_tilt_rotation, water_tilt_impulse_scalar )
	elif left_p:
		tilt( rotate_to_camera_normal(Vector2(-1, 0)), time_to_45_tilt_rotation, water_tilt_impulse_scalar )
	elif right_p:
		tilt( rotate_to_camera_normal(Vector2(1, 0)), time_to_45_tilt_rotation, water_tilt_impulse_scalar )
	elif up_p:
		tilt( rotate_to_camera_normal(Vector2(0, -1)), time_to_45_tilt_rotation, water_tilt_impulse_scalar )
	elif down_p:
		tilt( rotate_to_camera_normal(Vector2(0, 1)), time_to_45_tilt_rotation, water_tilt_impulse_scalar )
	elif left_jr or right_jr or up_jr or down_jr:
		stop_tilt()


	if Input.is_action_just_pressed("jump"):
		$sprite.play("Swim")
	elif Input.is_action_just_released("jump"):
		increase_water_resistance()


