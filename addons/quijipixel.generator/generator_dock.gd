tool
extends Panel

const LIST_FILE = "res://addons/quijipixel.generator/list.json"

var JsonLib = load("res://addons/quijipixel.generator/lib/json.gd")

var list = {}
var json_b = null

func _ready():
	set_name("Generator")

func configure_components():
	json_b = JsonLib.new()
	
	var file = File.new()
	if not file.file_exists(LIST_FILE):
		file.open(LIST_FILE, File.WRITE)
		file.store_line(json_b.str_to_json(list))
		file.close()
	else:
		file.open(LIST_FILE, File.READ)
		list = parse_json(file.get_as_text())
		file.close()


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

