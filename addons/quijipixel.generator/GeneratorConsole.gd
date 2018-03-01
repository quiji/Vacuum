tool
extends WindowDialog

onready var console = $margins/panel/console
onready var ok_button = $margins/panel/ok_button


const RED = Color(1.0, 0.3, 0.3)
const BLUE = Color(0.3, 0.3, 1.0)
const GREEN = Color(0.3, 1.0, 0.3)

func _on_ok_button_pressed():
	hide()
	queue_free()


func run(gen):
	
	var type = gen.split(".")[0]
	match type:
		"SpriteAnim2D":
			generate_animation(get_parent().list.generators[gen])

func generate_animation(gen):
	var dir = Directory.new()
	ok_button.disabled = true
	
	br()
	br()
	print_line("Generating Sprite Animation 2D. Working on: ")
	print_line(gen.name, BLUE)
	br()
	print_line("Validating generator...")
	
	var validated = true
	if not gen.has("spritesheet") or not dir.file_exists(gen.spritesheet):
		print_line("Spritesheet not provided or invalid file.", RED)
		validated = false
	
	if not gen.has("target_dir") or not dir.dir_exists(gen.target_dir):
		print_line("Target directory not provided or invalid directory.", RED)
		validated = false

	br()
	if not validated:
		print_line("Couldn't generate animation scene.", RED)
	else:
		print_line("Generator validated! Proceeding to scene generation...", GREEN)
		print_line("Proceeding to scene generation...")
		
		

	ok_button.disabled = false

# Printing to console methods

func print_line(line, color=null):
	var pre=""
	var post=""
	if color != null:
		pre = "[color=#" + color.to_html() + "]"
		post ="[/color]"
	console.append_bbcode(pre+line+post)
	console.newline()
	
func br():
	console.newline()
