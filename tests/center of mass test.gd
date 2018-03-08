
extends Node2D

func _ready():
	$strange_circle/center_of_mass.debug = true

var data = null

func _on_Timer_timeout():
	var vect = $Sprite.position

	vect = vect.rotated(-PI/64)
	$Sprite.position = vect
	
	data = $strange_circle.get_gravity_from_center($Sprite.position)
	update()
	