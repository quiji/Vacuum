extends Node2D

var value = Vector2()
var color = null
var magnitude = 0

var default_font = null

func _ready():
	var label = Label.new()
	default_font = label.get_font("")
	label.free()

func set_value(val, col):
	value = val.normalized()
	magnitude = val.length()
	color = col
	
	update()
	
func _draw():
	var target = value * 50
	var the_name = get_name() + '-' + str(magnitude)
	draw_line(Vector2(), target, color, 2, true)
	draw_line(target, target + value * 5 , Color(0,0,0), 2, true)
	draw_string(default_font, target + value * 5, the_name, color)
	draw_string(default_font, target + value * 5, the_name, color)
	
	
	
	
