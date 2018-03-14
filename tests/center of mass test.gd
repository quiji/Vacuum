
extends Node2D

func _ready():
	$test/center.debug = true
	#$strange_circle/center_of_mass.debug = true

var data = null

func _on_Timer_timeout():
	var vect = $Sprite.position


	vect = vect.rotated(-PI/64)
	$Sprite.position = vect
	
	data = $test/center.get_gravity($Sprite.position)
	#data = $strange_circle/center_of_mass.get_gravity($Sprite.position)

	