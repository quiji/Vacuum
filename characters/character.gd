extends "res://classes/Character.gd"



######## Const Stats #########
var slope_stop_min_velocity = 5.0
var run_velocity = 100.0
var midair_move_velocity = 40.0
var max_x_distance_a_jump = 50.0
var max_x_distance_b_jump = 70.0
var jump_peak_height = 95.5

var smash_jump_impulse_scalar = 30.0
var swim_impulse_scalar = 190.0

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

######## Counters #########


func _ready():
	._ready()
	
	set_playable(true)
	
	time_to_peak_of_jump = max_x_distance_a_jump / run_velocity
	jump_initial_velocity_scalar = 2*jump_peak_height / time_to_peak_of_jump

	fall_gravity_scalar = -2*jump_peak_height*pow(run_velocity, 2.0) / pow(max_x_distance_b_jump, 2.0)
	lowest_gravity_scalar = -2*jump_peak_height*pow(run_velocity, 2.0) / pow(max_x_distance_a_jump, 2.0)
	highgest_gravity_scalar = lowest_gravity_scalar * 6
	
	set_gravity_scalar(lowest_gravity_scalar)
	
	# Maybe this goes in the platform? we can play with platforms with different values
	set_slope_stop_min_vel(slope_stop_min_velocity)

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


############
# Callback methods
############


func _on_animation_reaction(action):
	Console.l("action", action)
	match action:
		Glb.REACT_STEP:
			pass
		Glb.REACT_SWIMSTROKE: 
			add_swim_impulse(swim_impulse_scalar)

############
# Overriden methods
############


func on_gravity_center_changed():
	
	pass


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
			var impulse = -_normal * smash_jump_impulse_scalar * distance_squared / pow(jump_peak_height, 2.0)
			ground_object.apply_impulse(position, impulse)

	set_gravity_scalar(lowest_gravity_scalar)
	
	if not $sprite.is_playing("EndRoll"):
		if is_moving():
			$sprite.play("Run")
		elif not is_moving():
			$sprite.play("Idle")

func start_rolling():
	$sprite.play("StartRoll")

func end_rolling():
	$sprite.play("EndRoll")

func on_water_entered(water_bubble):
	$sprite.play("WaterIdle")


func _process_behavior(delta):

	if is_on_gravity_center():
		_gravity_behavior(delta)
	elif is_on_water_center():
		_water_behavior(delta)

func _gravity_behavior(delta):
	
	if is_rolling():
		
		move(run_velocity)
		
	elif Input.is_action_just_pressed("ui_left"):
		
		$sprite.play("Run")
		
		if is_on_ground():
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
		
		$sprite.play("Run")

		if is_on_ground():
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
		tilt( rotate_to_camera_normal(Vector2(-0.707107, -0.707107)) )
	elif left_p and down_p:
		tilt( rotate_to_camera_normal(Vector2(-0.707107, 0.707107)) )
	elif right_p and up_p:
		tilt( rotate_to_camera_normal(Vector2(0.707107, -0.707107)) )
	elif right_p and down_p:
		tilt( rotate_to_camera_normal(Vector2(0.707107, 0.707107)) )
	elif left_p:
		tilt( rotate_to_camera_normal(Vector2(-1, 0)) )
	elif right_p:
		tilt( rotate_to_camera_normal(Vector2(1, 0)) )
	elif up_p:
		tilt( rotate_to_camera_normal(Vector2(0, -1)) )
	elif down_p:
		tilt( rotate_to_camera_normal(Vector2(0, 1)) )
	elif left_jr or right_jr or up_jr or down_jr:
		stop_tilt()


	if Input.is_action_just_pressed("jump"):
		$sprite.play("Swim")
	elif Input.is_action_just_released("jump"):
		increase_water_resistance()



