tool
extends Node2D

export (float) var radius = 100 setget set_radius,get_radius

export (Color) var base_color = Color(1, 1, 1) setget set_base_color,get_base_color
export (Color) var border_color = Color(1, 1, 1) setget set_border_color,get_border_color
export (float) var border_size = 0 setget set_border_size,get_border_size


func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func get_radius():
	return radius
	
func set_radius(r):
	radius = r
	update()
	

func set_base_color(c):
	base_color = c
	update()

func get_base_color():
	return base_color


func set_border_color(c):
	border_color = c
	update()

func get_border_color():
	return border_color

func set_border_size(s):
	border_size = s
	update()

func get_border_size():
	return border_size

func _draw():
	if border_size == 0:
		draw_circle(Vector2(),radius, base_color)
	else:
		draw_circle(Vector2(),radius - border_size, base_color)
		
		var point_count = 200
		var angle_step = 2*PI / point_count
		var i = 0
		var prev_dot = null
		while i < point_count:
			var dot = Vector2(0, -1).rotated(angle_step * i) * (radius - border_size / 2)
			if prev_dot != null:
				draw_line(prev_dot, dot, border_color, border_size)
			prev_dot = dot
			i+=1
		draw_line(prev_dot, Vector2(0, -1).rotated(0) * (radius - border_size / 2), border_color, border_size)

