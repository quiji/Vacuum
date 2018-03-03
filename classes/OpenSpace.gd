extends Node2D

"""
func _ready():
	
	
	var children = get_children()
	var i = 0
	while i < children.size():
		if children[i].has_method("get_water_resistance_scalar"):
			var spr = Sprite.new()
			spr.texture = load("res://assets/dummies/demo.png")
			children[i].add_child(spr)
		i +=1
	pass
"""
func is_open_space():
	return true

func get_tree_pos():
	return 0


