tool
extends EditorPlugin


var dock = null
func _enter_tree():
	dock = preload("res://addons/quijipixel.generator/generator_dock.tscn").instance()

	add_control_to_dock( DOCK_SLOT_LEFT_UR, dock)
	
		
	dock.configure_components()
	#dock.set_file(LIST_FILE)
	#dock.set_list_items(list)
	#dock.populate()


func _exit_tree():
    remove_control_from_docks( dock ) 
    dock.free() 

