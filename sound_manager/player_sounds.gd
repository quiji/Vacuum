extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func swim():
	var sound_index = randi() % 4 

	if sound_index != 1:
		if not get_node("swim_0" + str(sound_index)).playing:
			get_node("swim_0" + str(sound_index)).play()
		else:
			$swim_01.play()
	elif not get_node("swim_01").playing:
			get_node("swim_01").play()
	else:
		$swim_02.play()
