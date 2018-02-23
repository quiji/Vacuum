extends RigidBody2D

var center_of_mass = null

func _ready():

	var has_sprite = false

	for child in get_children():
		if child.has_method("feed_normal_field"):
			center_of_mass = child
		elif child.is_class("Sprite"):
			has_sprite = true

	if not has_sprite:
		draw_shape()


func get_gravity_from_center(pos):
	var result = {gravity = Vector2(), normal = Vector2()}
	if center_of_mass != null:

		result.gravity = center_of_mass.get_gravity(pos)

		if rotation != 0:
			result.gravity = result.gravity.rotated(rotation)
	
		result.normal = -result.gravity

	return result
	

var shape = null
func draw_shape():
	for child in get_children():
		if child.is_class("CollisionPolygon2D"):
			shape = {
				form = "polygon",
				points = child.polygon,
				pos = child.position
			}
		elif child.is_class("CollisionShape2D") and child.get_shape().is_class("CircleShape2D"):
			shape = {
				form = "circle",
				radius = child.get_shape().radius,
				pos = child.position
			}
		elif child.is_class("CollisionShape2D") and child.get_shape().is_class("RectangleShape2D"):
			shape = {
				form = "rectangle",
				extents = child.get_shape().get_extents(),
				pos = child.position
			}
	update()

func _draw():
	
	if shape != null:
		var col = Color(1, 0.5, 0.6)
		match shape.form:
			"polygon":
				draw_polygon(shape.points, [col])
			"circle":
				draw_circle(shape.pos, shape.radius, col)
			"rectangle":
				var r = Rect2(shape.pos - shape.extents, shape.pos + shape.extents * 2)
				draw_rect(r, col)





