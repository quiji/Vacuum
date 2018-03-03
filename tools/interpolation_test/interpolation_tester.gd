
extends Node2D
var Smooth = preload("res://classes/Smoothstep.gd")



func _ready():
	
	$interpolator.set_method(self, "inter")
	$interpolator2.set_method(self, "inter2")



func inter(t):
	return Smooth.start2(t)

func inter2(t):
	return Smooth.blend(t, abs(Smooth.flip(1 / (t + 0.3))), Smooth.start2(t), 0.8)