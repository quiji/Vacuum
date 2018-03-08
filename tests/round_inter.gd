extends Node2D


var t = 0
#var v1 = Vector2(0.999634, 0.0027851).normalized()
#var v2 = Vector2(0.00238, -0.999997).normalized()
var v1 = Vector2(-1, 0.8).normalized()
var v2 = Vector2(0.00238, -0.999997).normalized()
var c1 = Vector2()
var offset1 = Vector2(-100, 0)

var c2 = Vector2()
var offset2 = Vector2(100, 0)


var time = 0
func _physics_process(delta):
	
	
	if t < 1:
		t += delta / 1
		time += delta
		c2 = Glb.Smooth.directed_radial_interpolate(v1, v2, t, -1)
		c1 = Glb.Smooth.directed_radial_interpolate(v1, v2, t, 1)
	else:
		t = 0
		time = 0
		
	Console.add_log("t", t)
	Console.add_log("time", time)
	update()
	
func _draw():
	draw_line(offset1, offset1 + v1 * 50, Color(1, 0, 0), 4)
	draw_line(offset1, offset1 + v2 * 50, Color(0.5, 0, 0), 4)
	draw_line(offset1, offset1 + c1 * 50, Color(0, 0, 0.8), 4)

	draw_line(offset2, offset2 + v1 * 50, Color(1, 0, 0), 4)
	draw_line(offset2, offset2 + v2 * 50, Color(0.5, 0, 0), 4)
	draw_line(offset2, offset2 + c2 * 50, Color(0, 0, 0.8), 4)
