
extends Polygon2D


func _ready():

	generate_planes()

	Console.add_command("debug_normals", self, "debug_normals", "Show normals from center of mass nodes")
	




#########################################
# helper methods
#########################################


# moving! positive if to the right, negative if to the left of stationary
static func perp_prod(stationary, moving):
	return stationary.dot(moving.tangent())


########################################################################
# Some Plane magic!


# Debug vars!!
var current_planes = null
var __gravity = Vector2()
var __pos = Vector2()
var __result = -1
var __closest = Vector2()

# Precalculated planes for fast normal generation
var planes = []

func generate_planes():
	planes = []
	var j = 0
	while j < polygon.size():
		var prev = j - 1 if j > 0 else polygon.size() - 1
		var current = j
		# Polygon MUST be created clockwise!!!!
		var vect = polygon[prev] - polygon[current]
		var length = vect.length()
		var normal = -vect.normalized().tangent()
		var distance = normal.dot(polygon[current])
		planes.push_back({n = normal, d = distance, p1 = prev, p2 = current, ls = length * length, l = length})
		j += 1


func dist_to_plane(plane_idx, pos):
	return planes[plane_idx].n.dot(pos) - planes[plane_idx].d

func plane_normal(plane_idx):
	return planes[plane_idx].n
	
func pos_in_plane(plane_idx, pos):
	return pos + dist_to_plane(plane_idx, pos) * -plane_normal(plane_idx)

func get_closest_point_to_pos(plane_idx, pos):
	var p = pos_in_plane(plane_idx, pos)
	var a = get_p1(plane_idx)
	var b = get_p2(plane_idx)
	
	if (a - p).length_squared() < (b - p).length_squared():
		return a
	else:
		return b

func get_p1(plane_idx):
	return polygon[planes[plane_idx].p1]
	
func get_p2(plane_idx):
	return polygon[planes[plane_idx].p2]

func get_plane_length_squared(plane_idx):
	return planes[plane_idx].ls

func is_point_between_plane_points(plane_idx, pos):
	var c = pos_in_plane(plane_idx, pos)
	var a = get_p1(plane_idx)
	var b = get_p2(plane_idx)
	var d = (c - a).length_squared() + (b - c).length_squared()

	return d - get_plane_length_squared(plane_idx) <= 0.00001

func is_vect_between_planes(plane1, plane2, vect):
	var pos = perp_prod(plane_normal(plane1), vect)
	var neg = perp_prod(plane_normal(plane2), vect)


	return pos > 0 and neg < 0

func get_common_point(plane1, plane2, pos):
	
	if planes[plane1].p2 == planes[plane2].p1:
		return polygon[planes[plane1].p2]
	else:
		return polygon[planes[plane1].p1]



func get_polygonal_gravity(pos):

	var pos_normal = pos.normalized()
	var gravity = -pos_normal

	current_planes = []
	var i = 0
	
	var result = null
	
	while i < planes.size() and result == null:
		if dist_to_plane(i, pos) > 0:
			if is_point_between_plane_points(i, pos):
				result = i
			else:
				current_planes.push_back(i)
		i += 1

	if result != null:
		gravity = -plane_normal(result)
		__result = result
	elif current_planes.size() == 1:
		Console.count("weird_case")
		__result = current_planes[0]
		__closest = get_closest_point_to_pos(current_planes[0], pos)
		gravity = (__closest - pos).normalized()
	else:
		var closest = null
		var length = null
		var plane_1 = null
		var plane_2 = null
		var j = 0
		while j < current_planes.size():
			var p = get_closest_point_to_pos(current_planes[j], pos)
			var l = (pos - p).length_squared()
			if closest == null or l <= length:
				if plane_1 == null:
					plane_1 = current_planes[j]
				elif l == length:
					plane_2 = current_planes[j]
					j = current_planes.size()
				closest = p
				length = l

			j += 1
		var a = (pos_in_plane(plane_1, pos) - closest).length()
		var b = (pos_in_plane(plane_2, pos) - closest).length()
		length = a + b
		var t = a / length
		__closest = closest
		gravity = -Glb.Smooth.cross(t, plane_normal(plane_1), plane_normal(plane_2)).normalized()

	if debug:
		__pos = pos
		__gravity = gravity
		update()
	
	return gravity

#########################################
# Outside API method
#########################################

func get_gravity(pos):
	pos = pos - get_position()

	if polygon.size() > 0:
		return get_polygonal_gravity(pos)
	else:
		return -pos.normalized()
	
func get_poly_normals(rotation):
	var i = 0
	var normals = []
	while i < planes.size():
		normals.push_back(plane_normal(i))
		i += 1
	return normals

#########################
# DEBUG!
var debug = false

func debug_normals(args):
	debug = not debug
	update()

func _draw():
	
	if debug and polygon.size() > 0 :
	
		var i = 0
		while i < planes.size():
			var middle = ((polygon[planes[i].p1] + polygon[planes[i].p2]) / 2)
			var start = middle 
			draw_line(start, start + planes[i].n * 40, Color(1.0, 0, 0), 4)
			i += 1


		if current_planes != null:
			i = 0
			while i < current_planes.size():
				var j = current_planes[i]
				var middle = ((polygon[planes[j].p1] + polygon[planes[j].p2]) / 2)
				var start = middle 
				draw_line(start, start + planes[j].n * 40, Color(0, 0, 1.0), 4)
				draw_circle(pos_in_plane(j, __pos), 10, Color(0.2, 1.0, 0.2))
	
				i += 1
				
		if __result > -1:
			var middle = ((polygon[planes[__result].p1] + polygon[planes[__result].p2]) / 2)
			var start = middle 
			draw_line(start, start + planes[__result].n * 40, Color(0, 0, 1.0), 4)
			draw_circle(pos_in_plane(__result, __pos), 10, Color(0.2, 1.0, 0.2))
				
	
		draw_circle(__closest, 10, Color(0, 0, 0))
	
		draw_line(__pos, __pos + __gravity * 200, Color(0, 0, 0), 4)

	elif debug:
		draw_circle(Vector2(), 10, Color(0, 0, 0))

