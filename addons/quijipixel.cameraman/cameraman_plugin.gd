tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("CameraMan", "Camera2D", preload("CameraMan.gd"), preload("icon.png"))



func _exit_tree():
	remove_custom_type("CameraMan")
