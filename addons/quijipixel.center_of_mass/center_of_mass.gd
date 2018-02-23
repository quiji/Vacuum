extends Polygon2D

const SQUARE_DIRECTIONS = [Vector2(0, 1), Vector2(1, 0), Vector2(0, -1), Vector2(-1, 0)]


var _gravity_shapes = []
var _shape_metadata = []

var show_shapes = true

var _field_shape = null
var _field_meta = null

var _closest_center = Vector2()
var _avg_center_of_mass = Vector2()


export (NodePath) var field = null setget set_field, get_field

#########################################
# installation methods
#########################################

func _ready():

	if field != null:
		feed_normal_field(get_node(field))

	calculate_average_center_of_mass()

func feed_normal_field(field):

	if field.get_class() == "Polygon2D":
		
		_field_shape = field.get_polygon()
		_field_meta = get_polygon_metadata(field.get_polygon())
		
	if field.get_class() == "CollisionPolygon2D":
		
		_field_shape = field.get_polygon()
		_field_meta = get_polygon_metadata(field.get_polygon())
		
	elif field.get_class() == "CollisionShape2D" and field.get_shape().get_class() == "CircleShape2D":
		
		_field_shape = field.get_shape()
		_field_meta = get_circle_metadata(field.get_shape())
		
	elif field.get_class() == "CollisionShape2D" and field.get_shape().get_class() == "RectangleShape2D":
		
		var extents = field.get_shape().get_extents()
		_field_shape = field.get_shape()
		if extents.x == extents.y:
			_field_meta = get_square_metadata(field.get_shape())
		else:
			_field_meta = get_rectangle_metadata(field.get_shape())

func calculate_average_center_of_mass():

	var points = Vector2()
	if polygon.size() > 0:
		for point in polygon:
			points += point
			
		points /= polygon.size()
	_avg_center_of_mass = points

#########################################
# accesors
#########################################

func set_field(nd):
	field = nd

func get_field():
	return get_node(field)

func get_avg_center_of_mass():
	return _avg_center_of_mass

#########################################
# helper methods
#########################################


func calc_peak_factor(p1, center, p2):
	
	var a = (p1 - center).normalized()
	var b = (p2 - center).normalized()
	var c = -center.normalized()

	return (a.dot(c) + b.dot(c)) / 2

func calc_closest_center(pos):
	var i = 0
	_closest_center = Vector2()
	if _field_meta.type == "circle" or _field_meta.type == "square" or _field_meta.type == "rectangle":
		i = polygon.size()

	var closest_length = null
	var second_length = null
	var second_center = Vector2()
	while i < polygon.size():
		var new_center = polygon[i]
		var new_length = (new_center - pos).length_squared()
		if closest_length == null or new_length < closest_length:
			second_length = closest_length
			second_center = _closest_center
			closest_length = new_length
			_closest_center = new_center
		elif second_length == null or new_length < second_length:
			second_length = new_length
			second_center = new_center
		i += 1
	if closest_length != null and second_length != null:
		var center_factor = 0.5 * closest_length / second_length
		_closest_center = (second_center - _closest_center) * center_factor + _closest_center
		

func get_closest_direction(vect, directions):
	var biggest_dot = -1
	var biggest_direction = vect
	
	for dir in directions:
		var current_dot = dir.dot(vect)
		if current_dot > biggest_dot:
			biggest_dot = current_dot
			biggest_direction = dir
	
	return biggest_direction


# moving! positive if to the right, negative if to the left of stationary
static func perp_prod(stationary, moving):
	return stationary.dot(moving.tangent())

func get_closest_gravity_between_vertex(vect, vertex):

	var result = Vector2()
	var closest_points = []
	var i = 0
	var first_vertex = Vector2()
	var first_perp_prod = 0
	var prev_vertex = Vector2()
	var prev_perp_prod = 0
	var found = false
	vect = -vect
	while i < vertex.size() and not found:
		var current_vertex = (vertex[i] - _closest_center)
		var current_perp_prod = perp_prod(current_vertex, vect)
		if i > 0 and prev_perp_prod > 0 and current_perp_prod < 0:
			result = (current_vertex - prev_vertex).tangent().normalized()
			closest_points.push_back(i)
			closest_points.push_back(i - 1)
			found = true
		elif i == 0:
			first_vertex = current_vertex
			first_perp_prod = current_perp_prod
		prev_vertex = current_vertex
		prev_perp_prod = current_perp_prod
		i += 1

	if not found and prev_perp_prod > 0 and first_perp_prod < 0:
		result = (first_vertex - prev_vertex).tangent().normalized()
		closest_points.push_back(0)
		closest_points.push_back(vertex.size() - 1)

	return {g = -result, closest = closest_points}


#########################################
# circle methods
#########################################

func get_circle_metadata(shape):
	return {type = "circle"}

func get_circular_gravity(pos):
	var gravity = (_closest_center - pos).normalized()
	return gravity


#########################################
# square methods
#########################################


func get_square_metadata(shape):
	var extents = shape.get_extents()
	var squared_radius = pow(extents.x, 2.0)
	# Pytagoras theorem, simple
	return {type = "square", max_squared_radius = squared_radius + squared_radius }



func get_squared_gravity(pos):
	var gravity = _closest_center - pos
	var distance = gravity.length_squared()
	var clossines_to_edge = distance / _field_meta.max_squared_radius
	
	gravity = gravity.normalized()
	var base_gravity_direction = get_closest_direction(gravity, SQUARE_DIRECTIONS)
	
	if clossines_to_edge > 0.95:
		gravity = (base_gravity_direction + 2*gravity).normalized()
	else:
		gravity = base_gravity_direction

	return gravity


#########################################
# rectangle methods
#########################################

func get_rectangle_metadata(shape):
	var extents = shape.get_extents()
	var result = {type = "rectangle", axis_directions = [], max_squared_radius = null, circle_center_1 = null, circle_center_2 = null}

	var vector_a = Vector2(extents.x, 0)
	var vector_b = Vector2(0, extents.y)
	result.axis_directions.push_back((vector_a + vector_b).normalized())

	vector_a = Vector2(extents.x, 0)
	vector_b = Vector2(0, -extents.y)
	result.axis_directions.push_back((vector_a + vector_b).normalized())

	vector_a = Vector2(-extents.x, 0)
	vector_b = Vector2(0, -extents.y)
	result.axis_directions.push_back((vector_a + vector_b).normalized())

	vector_a = Vector2(-extents.x, 0)
	vector_b = Vector2(0, extents.y)
	result.axis_directions.push_back((vector_a + vector_b).normalized())

	
	var squared_a = pow(extents.x, 2.0)
	var squared_b = pow(extents.y, 2.0)
	# Pytagoras theorem, simple
	result.max_squared_radius = squared_a + squared_b
	
	if extents.x > extents.y:
		result.circle_center_1 = Vector2(extents.x - extents.y, 0)
	else:
		result.circle_center_1 = Vector2(0, extents.y - extents.x)
	result.circle_center_2 = -result.circle_center_1
	return result

func get_rectangular_gravity(pos):

	var gravity = _closest_center - pos
	var distance = gravity.length_squared()
	var clossines_to_edge = distance / _field_meta.max_squared_radius
	
	gravity = gravity.normalized()
	var base_gravity_direction = get_closest_gravity_between_vertex(gravity, _field_meta.axis_directions).g
	
	if clossines_to_edge > 0.95:
		var gravity_1 = (_field_meta.circle_center_1 + _closest_center - pos)
		var gravity_2 = (_field_meta.circle_center_2 + _closest_center - pos)
		
		if gravity_1.length_squared() > gravity_2.length_squared():
			gravity_2 = gravity_2.normalized()
			gravity = (base_gravity_direction + 2*clossines_to_edge*gravity_2).normalized()
		else:
			gravity_1 = gravity_1.normalized()
			gravity = (base_gravity_direction + 2*clossines_to_edge*gravity_1).normalized()

	else:
		gravity = base_gravity_direction

	return gravity



#########################################
# polygon methods BOTH METHODS ARE STILL ON MOVING PROCESS
#########################################

func get_polygon_metadata(vertex):
	var result = {type = "polygon", peak_factor = [], axis_directions = []}
	var i = 0
	
	for vect in vertex:
		result.axis_directions.push_back(vect)
		if i > 0 and i < vertex.size() - 1:
			result.peak_factor.push_back(calc_peak_factor(vertex[i - 1], vect, vertex[ i + 1]))
		else:
			result.peak_factor.push_back(0)
		i += 1

	result.peak_factor[0] = calc_peak_factor(vertex[vertex.size() - 1], vertex[0], vertex[1])
	result.peak_factor[vertex.size() - 1] = calc_peak_factor(vertex[vertex.size() - 2], vertex[vertex.size() - 1], vertex[0])

	return result



func get_polygonal_gravity(pos):

	var gravity = _closest_center - pos
	
	gravity = gravity.normalized()
	
	
	var gravity_data = get_closest_gravity_between_vertex(gravity, _field_meta.axis_directions)
	var base_gravity_direction = gravity_data.g

	var rot = get_parent().get_rotation()
	
	var clossines_to_edge = 0
	
	var p1 = _field_meta.axis_directions[gravity_data.closest[0]]
	var p2 = _field_meta.axis_directions[gravity_data.closest[1]]
	var p3 = pos
	
	var p3_norm = p3.normalized()
	var center_segment1 = (_closest_center - p1) / 5
	var center_segment2 = (_closest_center - p2) / 5
		
	var dir1_dot = (p3 - p1).normalized().dot(p3_norm)
	var dir2_dot = (p3 - p2).normalized().dot(p3_norm)

	var distance_a = (p1 - p3).length_squared()
	var distance_b= (p2 - p3).length_squared()
	var distance = 0
	var clossines_is_dot = true
	var peak_fact = 0

	if distance_a < distance_b:
		distance = distance_a
		peak_fact = _field_meta.peak_factor[gravity_data.closest[0]]
	else:
		distance = distance_b
		peak_fact = _field_meta.peak_factor[gravity_data.closest[1]]

	# if on air, we are using the direction from the dots rather than the length percentage as edge softener
	if dir1_dot > 0.2 and dir2_dot > 0.2 and distance > 80:
		#if dir1_dot > dir2_dot:
		if distance_a < distance_b:
			clossines_to_edge = dir1_dot
			# as new gravity center we are using the dots position to create a circular pull
			# but to soften its direction we are pulling the point gravity to the center of the shape
			
			gravity = ((p1 + center_segment1) - p3).normalized() 
		else:
			clossines_to_edge = dir2_dot
			gravity = ((p2 + center_segment2) - p3).normalized() 
	else:
		clossines_to_edge = 1 - distance / (p2 - p1).length_squared()
		clossines_is_dot = false

	

	var circular_gravity_weight = 2
	if clossines_is_dot:
		
		if clossines_to_edge > 0.8:
			circular_gravity_weight = 4 * clossines_to_edge
		else:
			circular_gravity_weight = 0.1 * clossines_to_edge / 0.8
	else:
		if clossines_to_edge > 0.9995:
			circular_gravity_weight = 0.4 * clossines_to_edge
		else:
			circular_gravity_weight = 0.01 * clossines_to_edge / 0.8


	gravity = (circular_gravity_weight * abs(peak_fact) * gravity + (1 - peak_fact) * base_gravity_direction).normalized()

	
	return gravity


#########################################
# gravity method
#########################################

func get_gravity(pos):
	pos = pos - get_position()
	calc_closest_center(pos)
	
	if _field_meta != null:
		match _field_meta.type:
			"circle": 
				return get_circular_gravity(pos)
			"square": 
				return get_squared_gravity(pos)
			"rectangle": 
				return get_rectangular_gravity(pos)
			"polygon": 
				return get_polygonal_gravity(pos)
	else: 
		return Vector2()

