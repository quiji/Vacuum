#extends RigidBody2D
extends KinematicBody2D


export (int, "NO_ROTATION", "CIRCULAR", "FOLLOW_LINE", "FOLLOW_POLY4", "FOLLOW_CUSTOM_POLY") var camera_rotation_mode = 0 setget set_camera_rotation_mode,get_camera_rotation_mode

var center_of_mass = null
var center_of_mass_normals = null
func _ready():

	var has_sprite = false

	for child in get_children():
		if child.has_method("get_polygonal_gravity"):
			center_of_mass = child
			center_of_mass_normals = center_of_mass.get_poly_normals(rotation)
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


func apply_impulse(impulse):
	# Nope, not doing this
	pass


###################################################################################
# Virtual methods

# This method must be overriden for platforms with different layers of visuals, so the player stays behind the important ones?? I guess?
func get_tree_pos():
	return 0

func set_camera_rotation_mode(m):
	camera_rotation_mode = m

func get_camera_rotation_mode():
	return Glb.CameraCrew.FOLLOW_CUSTOM_POLY
	#return Glb.CameraMan.CIRCULAR
	return camera_rotation_mode

func get_rotation_snapper():
	match camera_rotation_mode:
		Glb.CameraCrew.FOLLOW_LINE:
			return [Vector2(0, 1).rotated(rotation), Vector2(0, -1).rotated(rotation)]
		Glb.CameraCrew.FOLLOW_POLY4:
			return Glb.VectorLib.POLY4
		Glb.CameraCrew.FOLLOW_CUSTOM_POLY:
			return center_of_mass_normals

	return Glb.VectorLib.POLY4
