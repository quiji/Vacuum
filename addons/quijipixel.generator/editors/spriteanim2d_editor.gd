tool
extends WindowDialog

var _id = null
var gen = null

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func edit_generator(id):
	_id = id
	gen = get_parent().list.generators[id]
	window_title = "Sprite Animation 2D Editing: " + gen.name

	if gen.has("sprite_width"):
		$margins/spritesheet_size/sprite_sheet_width_edit.text = str(gen.sprite_width)

	if gen.has("sprite_height"):
		$margins/spritesheet_size/sprite_sheet_height_edit2.text = str(gen.sprite_height)

	if gen.has("spritesheet"):
		$margins/spritesheet_edit.text = gen.spritesheet
		load_sprite()



func _on_cancel_button_pressed():
	hide()

func _on_save_button_pressed():

	get_parent().list.generators[_id] = gen
	get_parent().save_list_to_file()
	hide()
	
func _on_save_gen_button_pressed():

	get_parent().list.generators[_id] = gen
	get_parent().save_list_to_file()
	get_parent().run_generator(_id)
	hide()


func load_sprite():
	$margins/sprite_preview/sprite.position = $margins/sprite_preview.rect_size / 2
	$margins/sprite_preview/sprite.texture = load(gen.spritesheet)
	var size = $margins/sprite_preview/sprite.texture.get_size()

	if gen.has("sprite_width") and gen.has("sprite_height"):
		$margins/sprite_preview/sprite.vframes = int(size.y / int(gen.sprite_height))
		$margins/sprite_preview/sprite.hframes = int(size.x / int(gen.sprite_width))
		size = Vector2(gen.sprite_width, gen.sprite_height)

	var scale = Vector2()
	if size.x > size.y:
		scale.x = $margins/sprite_preview.rect_size.x / size.x
		scale.y = scale.x
	else: 
		scale.y = $margins/sprite_preview.rect_size.y / size.y
		scale.x = scale.y
		
	$margins/sprite_preview/sprite.scale = scale
	


func _on_spriteanim2d_editor_popup_hide():
	self.queue_free()



func _on_sprite_sheet_width_edit_text_entered(new_text):
	if new_text.is_valid_integer() or new_text.is_valid_float():
		gen.sprite_width = int(new_text)
		load_sprite()

func _on_sprite_sheet_height_edit2_text_entered(new_text):
	if new_text.is_valid_integer() or new_text.is_valid_float():
		gen.sprite_height = int(new_text)
		load_sprite()

func _on_spritesheet_edit_text_entered(new_text):
	var file = File.new()
	if file.file_exists(new_text):
		gen.spritesheet = new_text
		load_sprite()

