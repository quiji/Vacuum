#extends RigidBody2D
extends KinematicBody2D

func _ready():

	var has_sprite = false

	for child in get_children():
		if child.is_class("Sprite"):
			has_sprite = true

	if not has_sprite:
		draw_shape()
	

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
		var col = Color(0.5, 0.9, 0.6)
		match shape.form:
			"polygon":
				draw_polygon(shape.points, [col])
			"circle":
				draw_circle(shape.pos, shape.radius, col)
			"rectangle":
				var r = Rect2(shape.pos - shape.extents, shape.pos + shape.extents * 2)
				draw_rect(r, col)



func apply_impulse(impulse):
	# Nope, not doing this
	pass


