tool
extends WindowDialog

var _id = null
var gen = null

onready var debug = $margins/debug
onready var spritesheet_edit = $margins/spritesheet/spritesheet_edit
onready var spritesheet_width_edit = $margins/spritesheet/spritesheet_size/sprite_sheet_width_edit
onready var spritesheet_height_edit = $margins/spritesheet/spritesheet_size/sprite_sheet_height_edit2
onready var sprite_preview = $margins/sprite_preview/sprite
onready var sprite_preview_panel = $margins/sprite_preview
onready var new_anim_name_edit = $margins/animation_list/new_anim_name
onready var animation_list = $margins/animation_list/list
onready var animation_editor = $margins/animation
onready var animation_editor_name = $margins/animation/animation_name

func _ready():
	# Called every time the node is added to the scene.
	# Initialization here
	pass

func edit_generator(id):
	_id = id
	gen = get_parent().list.generators[id]
	window_title = "Sprite Animation 2D Editing: " + gen.name

	if gen.has("sprite_width"):
		spritesheet_width_edit.text = str(gen.sprite_width)

	if gen.has("sprite_height"):
		spritesheet_height_edit.text = str(gen.sprite_height)

	if gen.has("spritesheet"):
		spritesheet_edit.text = gen.spritesheet
		load_sprite()

	if gen.has("animations"):
		for key in gen.animations:
			animation_list.add_item(key)


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
	sprite_preview.position = sprite_preview_panel.rect_size / 2
	sprite_preview.texture = load(gen.spritesheet)
	var size = sprite_preview.texture.get_size()

	if gen.has("sprite_width") and gen.has("sprite_height"):
		sprite_preview.vframes = int(size.y / int(gen.sprite_height))
		sprite_preview.hframes = int(size.x / int(gen.sprite_width))
		size = Vector2(gen.sprite_width, gen.sprite_height)

	var scale = Vector2()
	if size.x > size.y:
		scale.x = sprite_preview_panel.rect_size.x / size.x
		scale.y = scale.x
	else: 
		scale.y = sprite_preview_panel.rect_size.y / size.y
		scale.x = scale.y
		
	sprite_preview.scale = scale
	


func _on_spriteanim2d_editor_popup_hide():
	self.queue_free()



func _on_sprite_sheet_width_edit_text_entered(new_text):
	if new_text.is_valid_integer() or new_text.is_valid_float():
		gen.sprite_width = int(new_text)
		load_sprite()
	else:
		# Not valid integer
		pass

func _on_sprite_sheet_height_edit2_text_entered(new_text):
	if new_text.is_valid_integer() or new_text.is_valid_float():
		gen.sprite_height = int(new_text)
		load_sprite()
	else:
		# Not valid integer
		pass

func _on_spritesheet_edit_text_entered(new_text):
	var file = File.new()
	if file.file_exists(new_text):
		gen.spritesheet = new_text
		load_sprite()
	else:
		# File doesn't exist
		pass





func _on_remove_animation_button_pressed():
	var ids = animation_list.get_selected_items()
	if ids.size() > 0:
		var anim_name = animation_list.get_item_text(ids[0])
		animation_editor.hide()
		animation_list.remove_item(ids[0])
		gen.animations.erase(anim_name)
	else:
		# No animation is selected for deletion
		pass # replace with function body


func _on_new_animation_button_pressed():
	new_anim_name_edit.show()
	new_anim_name_edit.text = 'Animation Name'
	new_anim_name_edit.grab_focus()
	new_anim_name_edit.select_all()

func _on_new_anim_name_text_entered(new_text):
	if not gen.has("animations"):
		gen.animations = {}

	if not gen.animations.has(new_text):
		gen.animations[new_text] = {}

		new_anim_name_edit.hide()
		animation_list.add_item(new_text)
		animation_list.select(animation_list.get_item_count() - 1)
		_on_list_item_selected(animation_list.get_item_count() - 1)
	else:
		# That animation already exists
		pass



func _on_list_item_selected(index):

	var anim_name = animation_list.get_item_text(index)
	animation_editor.show()
	animation_editor_name.text = "Editing " + anim_name
	
	if gen.animations[anim_name].has("frames"):
		pass

