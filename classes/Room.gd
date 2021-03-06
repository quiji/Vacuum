extends Node2D


export (int, "NO_ROTATION", "CIRCULAR", "FOLLOW_LINE", "FOLLOW_POLY4", "FOLLOW_CUSTOM_POLY") var camera_rotation_mode = 0 setget set_camera_rotation_mode,get_camera_rotation_mode

func _ready():

	var has_sprite = false

	for child in get_children():
		if child.is_class("Sprite"):
			has_sprite = true

	if not has_sprite:
		draw_shape()
	

func is_room():
	return true

func get_gravity_from_center(pos):
	return {gravity = Vector2(0, 1), normal = Vector2(0, -1)}


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

###################################################################################
# Virtual methods

# This method must be overriden for platforms with different layers of visuals, so the player stays behind the important ones?? I guess?
func get_tree_pos():
	return 0

func set_camera_rotation_mode(m):
	camera_rotation_mode = m

func get_camera_rotation_mode():
	return Glb.CameraCrew.NO_ROTATION

func get_rotation_snapper():
	return Glb.VectorLib.POLY4
