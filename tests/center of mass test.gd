
extends KinematicBody2D

var data = null

func _on_Timer_timeout():
	var vect = $Sprite.position

	vect = vect.rotated(-PI/64)
	$Sprite.position = vect
	
	data = $CenterOfMass.get_gravity($Sprite.position)
	update()
	