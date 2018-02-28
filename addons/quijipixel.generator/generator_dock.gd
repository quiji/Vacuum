tool
extends Panel

const LIST_FILE = "res://addons/quijipixel.generator/list.json"

enum GeneratorTypes {SpriteAnim2D = 0}

var JsonLib = load("res://addons/quijipixel.generator/lib/json.gd")

var list = {generators = {}, last_id = 0}
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
	$create_dialog/error_text.text = ''


func _on_create_button_pressed():
	if $create_dialog/name_edit.text.strip_edges() == "":
		$create_dialog/error_text.text = "The Generator must have a name!!"
	else:
		$create_dialog.hide()
		var id = list.last_id
	
		match $create_dialog/type_select.get_selected_id():
			SpriteAnim2D:
				id = "SpriteAnim2D." + str(id)
				list.generators[id] = {
					name = $create_dialog/name_edit.text
				}
				list.last_id += 1
				pass
	
		save_list_to_file()


func _on_cancel_button_pressed():
	$create_dialog.hide()


func save_list_to_file():
	var file = File.new()
	file.open(LIST_FILE, File.WRITE)
	file.store_line(json_b.str_to_json(list))
	file.close()



