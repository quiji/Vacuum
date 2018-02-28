tool
extends Panel

func _ready():
	set_name("Generator")
	


func _on_add_generator_button_pressed():
	$create_dialog.popup_centered()
	$create_dialog/name_edit.text = ''


func _on_create_button_pressed():
	$create_dialog.hide()


func _on_cancel_button_pressed():
	$create_dialog.hide()


func _on_type_select_item_selected(ID):
	match ID:
		0:
			$create_dialog/type_text.text = "any"

