extends KinematicBody2D


const WATER_RESISTANCE = 200.5
const WATER_RESISTANCE_SQUARED = WATER_RESISTANCE * WATER_RESISTANCE
#const WATER_RESISTANCE = 251.5
"""
const WATER_NORMAL_WAVE_SPEED = 1.8
const WATER_SWIM_WAVE_SPEED = 15.2
const WATER_ENTER_WAVE_SPEED = 28.2
const WATER_FREQUENCY = 16
const WATER_WAVE_DEPTH = 0.005
"""

const WATER_NORMAL_WAVE_SPEED = 0.9
const WATER_SWIM_WAVE_SPEED = 8.6
const WATER_ENTER_WAVE_SPEED = 14.1
const WATER_FREQUENCY = 8
const WATER_WAVE_DEPTH = 0.0028

const WATER_INNER_RADIUS = 16.8
const WATER_RADIUS_LIMIT = 23.8


export (float) var radius = 120 setget set_radius,get_radius

var pending_point = null

var wave_speed = 0


var squared_radius = radius * radius

func _ready():
	
	$collision.shape = $collision.shape.duplicate(true)
	$water_reaction_area/collision.shape = $water_reaction_area/collision.shape.duplicate(true)


	var bkg = preload("res://tools/Circle.tscn").duplicate(true).instance()
	bkg.set_name("bkg")
	add_child(bkg)
	move_child(bkg, 0)
	bkg.set_radius(120)
	bkg.set_base_color(Color(1, 1, 1, 0))
	bkg.set_border_color(Color(1, 1, 1))
	bkg.set_border_size(3)

	var bubble = Sprite.new()
	bubble.set_name("bubble_texture")
	bubble.texture = load("res://assets/shader_base/bubble_base.png")
	bubble.modulate = Color(1, 1, 1, 0.02)
	add_child(bubble)
	move_child(bubble, 0)
	
	$water_shader.material = $water_shader.material.duplicate(true)
	$color_shader.material = $color_shader.material.duplicate(true)
	
	$water_shader.material.set("shader_param/frequency", WATER_FREQUENCY)
	$water_shader.material.set("shader_param/depth", WATER_WAVE_DEPTH)

	wave_speed = WATER_NORMAL_WAVE_SPEED

	$water_reaction_area.connect("body_entered", self, "on_body_in")
	$water_reaction_area.connect("body_exited", self, "on_body_out")

	$water_ambience.volume_db = -80
	$water_ambience2.volume_db = -80
	$tween.connect("tween_completed", self, "on_tween_completed")
	
	
	setup_radial_structures()

func set_radius(r):
	radius = r
	squared_radius = radius * radius
	if has_node("bkg") and $bkg != null:
		setup_radial_structures()

func get_radius():
	return radius

func get_inner_limit_radius():
	return radius - WATER_RADIUS_LIMIT

# This method must be overriden for platforms with different layers of visuals, so the player stays behind the important ones?? I guess?
func get_tree_pos():
	return 0

func get_last_velocity():
	return Vector2()

func grow(r):
	
	var speed = r / 30.0 
	
	$tween.interpolate_property(self, "radius", radius, radius + r, speed, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$tween.start()
	
func shrink(r):
	var speed = r / 30.0 
	
	$tween.interpolate_property(self, "radius", radius, radius - r, speed, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$tween.start()

func setup_radial_structures():
	var margin = 0.0075
	$bkg.set_radius(radius - margin * 250)
	$bubble_texture.scale = Vector2(radius / 60, radius / 60)
	$color_shader.set_radius(radius)
	
	$collision.shape.radius = radius - WATER_INNER_RADIUS
	$water_reaction_area/collision.shape.radius = radius * (1 + margin)
	

	#$water_shader.set_radius(radius * 1.02)
	$water_shader.set_radius(radius * (1 + margin))
	$water_shader.material.set("shader_params/radius", radius * (1 + margin))
	$color_shader.material.set("shader_params/radius", radius)

	

func get_water_resistance_scalar():
	return -WATER_RESISTANCE
	
func get_water_resistance_squared_scalar():
	return -WATER_RESISTANCE_SQUARED

func entering_water(body):
	Glb.music_water_bus()

	$water_ambience.play()
	$water_ambience2.play(0.8)
	$tween.interpolate_property($water_ambience, "volume_db", $water_ambience.volume_db, -15, 0.15, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$tween.interpolate_property($water_ambience2, "volume_db", $water_ambience.volume_db, -15, 0.15, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$tween.start()

func leaving_water(body):

	Glb.music_restore_bus()
	#$tween.interpolate_property($water_ambience, "volume_db", 0, -80, 0.15, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$tween.interpolate_property($water_ambience, "volume_db", -15, -80, 0.15, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$tween.interpolate_property($water_ambience2, "volume_db", -15, -80, 0.15, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$tween.start()


func on_body_in(body):
	set_wave_speed(WATER_ENTER_WAVE_SPEED)
	if body.has_method("set_water_center"):
		body.check_for_water_arrival(global_position, radius)

func on_body_out(body):
	set_wave_speed(WATER_ENTER_WAVE_SPEED)
	if body.has_method("set_water_center"):
		body.failed_water_arrival()


func on_tween_completed(obj, prop):
	if obj == $water_ambience and $water_ambience.volume_db == -80:
		$water_ambience.stop()

func child_movement(pos):
	var factor = pos.length() / radius 
	var speedo = clamp(WATER_SWIM_WAVE_SPEED * factor, WATER_NORMAL_WAVE_SPEED, WATER_SWIM_WAVE_SPEED)
	set_wave_speed(speedo)


func set_wave_speed(speedo):
	if wave_speed < speedo:
		wave_speed = speedo

func report_body(body, velocity):
	if body.has_method("limit_water_movement_on_edges"):
		return body.limit_water_movement_on_edges(radius - WATER_RADIUS_LIMIT, velocity)
	return velocity
	

var total_t = -1499990.0
func _physics_process(delta):
	total_t += delta * wave_speed

	if $water_shader != null:
		$water_shader.material.set("shader_param/delta", total_t)

	if wave_speed > WATER_NORMAL_WAVE_SPEED:
		wave_speed = lerp(wave_speed, WATER_NORMAL_WAVE_SPEED, delta / 2.0)
	
	
	if total_t > 1500000.0:
		total_t *= -1

