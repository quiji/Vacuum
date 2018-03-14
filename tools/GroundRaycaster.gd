tool
extends Node2D

export (Vector2) var a = Vector2() setget set_a,get_a
export (Vector2) var b = Vector2() setget set_b,get_b
export (Vector2) var c = Vector2() setget set_c,get_c

export (Vector2) var normal = Vector2(0, -1) setget set_normal,get_normal
export (bool) var show_lines = true setget set_show_lines,get_show_lines


func _ready():
	
	$point_a.position = a
	$point_b.position = b
	$point_c.position = c

	$head_ray.add_exception(get_parent())

func set_a(p):
	a = p

	if has_node("point_a") and (Engine.editor_hint or show_lines):
		$point_a.position = a
		$line_show.set_point_position(0, a)

func set_show_lines(s):
	show_lines = s
	if has_node("line_show"):
		if show_lines:
			$line_show.show()
		else:
			$line_show.hide()

func get_show_lines():
	return show_lines

func get_a():
	return a

func set_b(p):
	b = p

	if has_node("point_b") and (Engine.editor_hint or show_lines):
		$point_b.position = b
		$line_show.set_point_position(1, b)


func get_b():
	return b

func set_c(p):
	c = p

func get_c():
	return c

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

	var result =  space_state.get_rest_info(shape_query)
	if not result.empty():
		var colls = space_state.intersect_point(result.point - 5 * result.normal, 10, [get_parent()], collision_layer_int)

		if colls.size() == 0:
			colls = space_state.intersect_point($point_a.global_position - 5 * result.normal, 10, [get_parent()], collision_layer_int)

		if colls.size() == 0:
			colls = space_state.intersect_point($point_b.global_position - 5 * result.normal, 10, [get_parent()], collision_layer_int)

		var i = 0
		result.collider_count = 0
		result.gravity_centers = []
		result.small_platforms = []
		while i < colls.size():
			if colls[i].collider.has_method("get_gravity_from_center"):
				result.gravity_centers.push_back({collider = colls[i].collider, normal = result.normal})
				result.collider_count += 1
			elif normal.dot(result.normal) > 0.1:
				result.small_platforms.push_back({collider = colls[i].collider, normal = result.normal})
				result.collider_count += 1
			i += 1
		
	return result

func cast_water(collision_layer):
	
	if Engine.editor_hint:
		return null
	
	var ground_result = cast_ground(collision_layer)
	
	if not ground_result.empty():
		var collision_layer_int = collision_layer
		var space_rid = get_world_2d().get_space()
		var space_state = Physics2DServer.space_get_direct_state(space_rid)
		var result_a = space_state.intersect_point($point_a.global_position, 1, [get_parent()], collision_layer_int)
		var result_b = space_state.intersect_point($point_b.global_position, 1, [get_parent()], collision_layer_int)
		var result_ab = space_state.intersect_point(($point_a.global_position + $point_b.global_position) / 2, 1, [get_parent()], collision_layer_int)
		if result_a.size() > 0:
			return result_a[0]
		elif result_ab.size() > 0:
			return result_ab[0]
		elif result_b.size() > 0:
			return result_b[0]
	
	return {}
	
	var collision_layer_int = collision_layer
	var space_rid = get_world_2d().get_space()
	var space_state = Physics2DServer.space_get_direct_state(space_rid)
	
	return space_state.intersect_ray($point_a.global_position, $point_b.global_position, [get_parent()], collision_layer_int)


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

func cast_ray_ahead(motion, collision_layer):

	if Engine.editor_hint:
		return null

	var collision_layer_int = collision_layer
	var space_rid = get_world_2d().get_space()
	var space_state = Physics2DServer.space_get_direct_state(space_rid)
	
	var result = {}

	$head_ray.position = $point_c.position
	$head_ray.cast_to = motion
	$head_ray.force_raycast_update()


	if $head_ray.is_colliding():
		result = {
			collider = $head_ray.get_collider(),
			normal =  $head_ray.get_collision_normal(),
			point = $head_ray.get_collision_point(),
			is_headcast = true
		}


	
	return result


