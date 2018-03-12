extends Area2D

enum MarginQuery {MARGIN, INNER_MARGIN, OUTER_MARGIN}

var debug_cameraman = false
var poly = null
var inner_poly = null
var margin_size = 40

func _ready():
	collision_layer = Glb.get_collision_layer_int(["CameraActor"])
	collision_mask = Glb.get_collision_layer_int(["CameraActor"])
	
	create_shape_owner(self)
	poly = ConvexPolygonShape2D.new()
	poly.points = PoolVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)])

	inner_poly = ConvexPolygonShape2D.new()
	inner_poly.points = PoolVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)])
	
	shape_owner_add_shape(0, poly)
	shape_owner_add_shape(0, inner_poly)



func change_margins(left_dist, up_dist, right_dist, down_dist):

	poly.points[0].x = -left_dist - margin_size
	poly.points[0].y = -up_dist - margin_size

	poly.points[1].x = right_dist + margin_size
	poly.points[1].y = -up_dist - margin_size

	poly.points[2].x = right_dist + margin_size
	poly.points[2].y = down_dist + margin_size

	poly.points[3].x = -left_dist - margin_size
	poly.points[3].y = down_dist + margin_size

	inner_poly.points[0].x = -left_dist 
	inner_poly.points[0].y = -up_dist 

	inner_poly.points[1].x = right_dist
	inner_poly.points[1].y = -up_dist 

	inner_poly.points[2].x = right_dist
	inner_poly.points[2].y = down_dist 

	inner_poly.points[3].x = -left_dist
	inner_poly.points[3].y = down_dist 



	if debug_cameraman:
		update()

func _draw():
	if debug_cameraman:
		draw_line(poly.points[0], poly.points[1], Color(1.0, 0.2, 0.2), 2.0)
		draw_line(poly.points[1], poly.points[2], Color(1.0, 0.2, 0.2), 2.0)
		draw_line(poly.points[2], poly.points[3], Color(1.0, 0.2, 0.2), 2.0)
		draw_line(poly.points[3], poly.points[0], Color(1.0, 0.2, 0.2), 2.0)
		
		draw_line(inner_poly.points[0], inner_poly.points[1], Color(0.2, 1.0, 0.2), 2.0)
		draw_line(inner_poly.points[1], inner_poly.points[2], Color(0.2, 1.0, 0.2), 2.0)
		draw_line(inner_poly.points[2], inner_poly.points[3], Color(0.2, 1.0, 0.2), 2.0)
		draw_line(inner_poly.points[3], inner_poly.points[0], Color(0.2, 1.0, 0.2), 2.0)
		
		if get_parent().lock_actor.target != null:

			draw_line(Vector2(), get_parent().lock_actor.actor_movement, Color(0.8, 0.8, 1.0), 2)
			draw_line(Vector2(), get_parent().lock_actor.target - get_parent().lock_actor.current_pos, Color(0.8, 0.8, 0.8), 2)

func in_x_axis(pos_x):
	return inner_poly.points[0].x <= pos_x and pos_x <= inner_poly.points[1].x

func in_y_axis(pos_y):
	return inner_poly.points[0].y <= pos_y and pos_y <= inner_poly.points[3].y


func in_margins(actor_pos, type=MARGIN):

	var space_rid = get_world_2d().get_space()
	var space_state = Physics2DServer.space_get_direct_state(space_rid)
	var result_a = space_state.intersect_point(actor_pos, 1, [get_parent()._actor], collision_mask)

	if result_a.size() > 0:
		match type:
			INNER_MARGIN:
				return result_a[0].shape == 1
			OUTER_MARGIN:
				return result_a[0].shape == 0
			_:
				return true

	return false
