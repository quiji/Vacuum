tool
extends KinematicBody2D


const WATER_RESISTANCE = 200.5
const WATER_RESISTANCE_SQUARED = WATER_RESISTANCE * WATER_RESISTANCE
#const WATER_RESISTANCE = 251.5

const WATER_NORMAL_WAVE_SPEED = 1.8
const WATER_SWIM_WAVE_SPEED = 15.2
const WATER_ENTER_WAVE_SPEED = 28.2

export (float) var radius = 120 setget set_radius,get_radius

var pending_point = null

var wave_speed = 0


var squared_radius = radius * radius

func _ready():
	
	$collision.shape = $collision.shape.duplicate(true)

	#var bkg  = $bkg.duplicate(DUPLICATE_USE_INSTANCING)
	#$bkg.replace_by(bkg)

	#var color_shader = $color_shader.duplicate(DUPLICATE_USE_INSTANCING)
	#$color_shader.replace_by(color_shader)

	#var water_shader = $water_shader.duplicate(DUPLICATE_USE_INSTANCING)
	#$water_shader.replace_by(water_shader)



	$water_shader.material = $water_shader.material.duplicate(true)
	$color_shader.material = $color_shader.material.duplicate(true)
	

	wave_speed = WATER_NORMAL_WAVE_SPEED

	$water_reaction_area.connect("body_entered", self, "on_body_in")
	$water_reaction_area.connect("body_exited", self, "on_body_out")

	setup_radial_structures()

func set_radius(r):
	radius = r
	squared_radius = radius * radius
	if has_node("bkg") and $bkg != null:
		setup_radial_structures()

func get_radius():
	return radius

# This method must be overriden for platforms with different layers of visuals, so the player stays behind the important ones?? I guess?
func get_tree_pos():
	return 0


func grow(r):
	
	var speed = r / 30.0 
	
	$tween.interpolate_property(self, "radius", radius, radius + r, speed, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$tween.start()
	
func shrink(r):
	var speed = r / 30.0 
	
	$tween.interpolate_property(self, "radius", radius, radius - r, speed, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$tween.start()

func setup_radial_structures():
	$bkg.set_radius(radius)
	$color_shader.set_radius(radius)
	$collision.shape.radius = radius * 0.86
	$water_reaction_area/collision.shape.radius = radius

	$water_shader.set_radius(radius * 1.02)
	$water_shader.material.set("shader_params/radius", radius * 1.02)
	$color_shader.material.set("shader_params/radius", radius)


func get_water_resistance_scalar():
	return -WATER_RESISTANCE
	
func get_water_resistance_squared_scalar():
	return -WATER_RESISTANCE_SQUARED

func on_body_in(body):
	set_wave_speed(WATER_ENTER_WAVE_SPEED)


func on_body_out(body):
	
	set_wave_speed(WATER_ENTER_WAVE_SPEED)

func child_movement(pos, swim_impulse):
	var factor = pos.length_squared() / squared_radius 
	var speedo = clamp(WATER_SWIM_WAVE_SPEED * factor, WATER_NORMAL_WAVE_SPEED, WATER_SWIM_WAVE_SPEED)
	set_wave_speed(speedo)


func set_wave_speed(speedo):
	if wave_speed < speedo:
		wave_speed = speedo

func report_body(body):
	var inner_radius = radius * 0.86
	
	var normalized_dist = clamp(body.position.length_squared() / (inner_radius * inner_radius), 0.0, 1.0)

	var min_speed = 35
	var min_tilt_speed = 5
	min_speed *= min_speed
	min_tilt_speed *= min_tilt_speed

	if body.position.normalized().dot(body.swim_velocity) >= -0.1 and body.swim_velocity.length_squared() < min_speed and normalized_dist > 0.5:
		body.swim_velocity = body.swim_velocity.linear_interpolate(Vector2(), Glb.Smooth.test(normalized_dist))

	if body.position.normalized().dot(body.swim_tilt_velocity) >= -0.1 and body.swim_tilt_velocity.length_squared() < min_speed and normalized_dist > 0.5:
		body.swim_tilt_velocity = body.swim_tilt_velocity.linear_interpolate(Vector2(), Glb.Smooth.test(normalized_dist))


var total_t = -1499990.0
func _physics_process(delta):
	total_t += delta * wave_speed

	if $water_shader != null:
		$water_shader.material.set("shader_param/delta", total_t)

	if wave_speed > WATER_NORMAL_WAVE_SPEED:
		wave_speed = lerp(wave_speed, WATER_NORMAL_WAVE_SPEED, delta / 2.0)
	
	
	if total_t > 1500000.0:
		total_t *= -1

