
extends Node2D
var Smooth = preload("res://classes/Smoothstep.gd")



func _ready():
	
	$interpolator.set_method(self, "inter")
	$interpolator2.set_method(self, "inter2")
	$interpolator3.set_method(self, "inter3")
	$interpolator4.set_method(self, "inter4")
	$interpolator5.set_method(self, "inter5")



func inter(t):
	return Smooth.cam_circular_small_rot(t)

func inter2(t):
	return Smooth.cam_circular_full_rot(t)


func inter3(t):
	return Smooth.cam_circular_rot(t, 0.2)

func inter4(t):
	return Smooth.cam_circular_rot(t, 0.5)

func inter5(t):
	#return Smooth.cross(t, Smooth.arch(Smooth.stop6(t), 2), Smooth.flip(Smooth.arch(Smooth.start6(t), 0.5)))
	return Smooth.cam_circular_rot(t, 0.9)

