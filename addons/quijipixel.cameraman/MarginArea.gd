extends Area2D

var debug_cameraman = false
var poly = null

func _ready():
	collision_layer = Glb.get_collision_layer_int(["CameraActor"])
	collision_mask = Glb.get_collision_layer_int(["CameraActor"])
	
	create_shape_owner(self)
	poly = ConvexPolygonShape2D.new()
	poly.points = PoolVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)])

	
	shape_owner_add_shape(0, poly)
	
	#connect("body_entered", self, "on_body_entered")
	connect("body_exited", self, "on_body_exited")



func on_body_exited(body):
	if get_parent().scene_mode != get_parent().WATER_BUBBLE:
		get_parent().attempt_lock()
	#pass

func change_margins(left_dist, up_dist, right_dist, down_dist):
	poly.points[0].x = -left_dist
	poly.points[0].y = -up_dist

	poly.points[1].x = right_dist
	poly.points[1].y = -up_dist

	poly.points[2].x = right_dist
	poly.points[2].y = down_dist

	poly.points[3].x = -left_dist
	poly.points[3].y = down_dist


	if debug_cameraman:
		update()

func _draw():
	if debug_cameraman:
		draw_line(poly.points[0], poly.points[1], Color(1.0, 0.2, 0.2), 2.0)
		draw_line(poly.points[1], poly.points[2], Color(1.0, 0.2, 0.2), 2.0)
		
		draw_line(poly.points[2], poly.points[3], Color(0.2, 1.0, 0.2), 2.0)
		draw_line(poly.points[3], poly.points[0], Color(0.2, 1.0, 0.2), 2.0)


func in_margins(actor_pos):

	var space_rid = get_world_2d().get_space()
	var space_state = Physics2DServer.space_get_direct_state(space_rid)
	var result_a = space_state.intersect_point(actor_pos, 1, [get_parent()._actor], collision_mask)
	
	return result_a.size() > 0

