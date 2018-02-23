tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("CenterOfMass", "Polygon2D", preload("center_of_mass.gd"), preload("icon.png"))



func _exit_tree():
	remove_custom_type("CenterOfMass")
