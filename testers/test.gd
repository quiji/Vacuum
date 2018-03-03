
extends Node2D
var Smooth = preload("res://classes/Smoothstep.gd")


func _draw():
	var i = 0
	var pos1 = Vector2()
	var pos2 = Vector2()
	var pos3 = Vector2()
	var pos4 = Vector2()

	var prev1 = Vector2()
	var prev2 = Vector2()
	var prev3 = Vector2()
	var prev4 = Vector2()

	var pos5 = Vector2()
	var prev5 = Vector2()
	var pos6 = Vector2()
	var prev6 = Vector2()


	var p1 = Vector2(-100, 0)
	var p2 = Vector2(0, 0)
	while i <= 1:
		prev1 = pos1
		pos1 = Vector2(i * 100, -Smooth.arch2(i) * 100)
		draw_line(prev1 - p1, pos1 - p1, Color(1.0, 0.5, 0.6), 2.0)

		prev2 = pos2
		pos2 = Vector2(i * 100, -Smooth.start2(i) * 100)
		draw_line(prev2 - p1, pos2 - p1, Color(0.5, 1.0, 0.6), 2.0)

		prev3 = pos3
		pos3 = Vector2(i * 100, -Smooth.cross(i, Smooth.arch2(i), Smooth.start2(i)) * 100)
		draw_line(prev3 - p1, pos3 - p1, Color(0.5, 0.6, 1.0), 2.0)



		prev5 = pos5
		pos5 = Vector2(i * 100, -Smooth.blend(i, Smooth.arch2(i), Smooth.rev_scale(i, Smooth.arch2(i)), 0.8) * 100)
		draw_line(prev5 - p2, pos5 - p2, Color(1.0, 0.5, 0.6), 2.0)

		prev6 = pos6
		pos6 = Vector2(i * 100, -Smooth.scale(i, Smooth.arch2(i)) * 100)
		draw_line(prev6 - p2, pos6 - p2, Color(0.5, 0.6, 1.0), 2.0)


		prev4 = pos4
		pos4 = Vector2(i * 100, -Smooth.arch2(Smooth.rev_scale(i, Smooth.arch2(i))) * 100)
		draw_line(prev4 - p2, pos4 - p2, Color(0.5, 1.0, 0.6), 2.0)


		i += 0.01
	
	

