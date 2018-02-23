tool
extends Node2D

export (Vector2) var a = Vector2() setget set_a,get_a
export (Vector2) var b = Vector2() setget set_b,get_b
export (Vector2) var normal = Vector2(0, -1) setget set_normal,get_normal
export (bool) var show_lines = true


func _ready():
	
	$point_a.position = a
	$point_b.position = b


func set_a(p):
	a = p

	if has_node("point_a") and (Engine.editor_hint or show_lines):
		$point_a.position = a
		$line_show.set_point_position(0, a)

func get_a():
	return a

func set_b(p):
	b = p

	if has_node("point_b") and (Engine.editor_hint or show_lines):
		$point_b.position = b
		$line_show.set_point_position(1, b)


func get_b():
	return b

func set_normal(n):
	normal = n
	global_rotation = (-normal).angle() - PI/2

func get_normal():
	return normal

func cast_ground(collision_layer):
	
	if Engine.editor_hint:
		return null
	
	var collision_layer_int = collision_layer
	var space_rid = get_world_2d().get_space()
	var space_state = Physics2DServer.space_get_direct_state(space_rid)
	
	var line_cast = SegmentShape2D.new()
	
	line_cast.set_a($point_a.global_position)
	line_cast.set_b($point_b.global_position)
	
	var shape_query = Physics2DShapeQueryParameters.new()
	shape_query.set_collision_layer(collision_layer_int)
	shape_query.set_exclude([get_parent()])
	shape_query.set_margin(0.08)
	shape_query.set_motion(Vector2())
	
	shape_query.set_shape(line_cast)

	return space_state.get_rest_info(shape_query)


func cast_movement(motion, collision_layer):

	if Engine.editor_hint:
		return null

	var collision_layer_int = collision_layer
	var space_rid = get_world_2d().get_space()
	var space_state = Physics2DServer.space_get_direct_state(space_rid)

	var line_cast = SegmentShape2D.new()
	
	line_cast.set_a($point_a.global_position + normal)
	line_cast.set_b($point_b.global_position + normal)

	
	var shape_query = Physics2DShapeQueryParameters.new()
	shape_query.set_collision_layer(collision_layer_int)
	shape_query.set_exclude([get_parent()])
	shape_query.set_margin(0.08)
	shape_query.set_motion(motion)
	
	shape_query.set_shape(line_cast)

	var rest_result = space_state.get_rest_info(shape_query)
	var motion_result = space_state.cast_motion(shape_query)
		
	return {rest = rest_result, motion = motion_result}

