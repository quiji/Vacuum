extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

var t = 0
#var v1 = Vector2(0.999634, 0.0027851).normalized()
#var v2 = Vector2(0.00238, -0.999997).normalized()
var v1 = Vector2(1.8, 1).normalized()
var v2 = Vector2(0.00238, -0.999997).normalized()
var c = Vector2()
var time = 0
func _physics_process(delta):
	
	
	if t < 1:
		t += delta / 12
		time += delta
		c = Glb.Smooth.directed_radial_interpolate(v1, v2, t, 1)
	else:
		t = 0
		time = 0
		
	Console.add_log("t", t)
	Console.add_log("time", time)
	update()
	
func _draw():
	draw_line(Vector2(), v1 * 50, Color(1, 0, 0), 4)
	draw_line(Vector2(), v2 * 50, Color(0.5, 0, 0), 4)
	draw_line(Vector2(), c * 50, Color(0, 0, 0.8), 4)