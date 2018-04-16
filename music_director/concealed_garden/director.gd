extends Node

var next_section = null
var current_section = null

func _ready():
	$"intro A".connect("finished", self, "finished_section")
	$"intro B".connect("finished", self, "finished_section")
	$"intro C".connect("finished", self, "finished_section")

func start():
	$"intro A".play()
	current_section = "intro A"


func go_to_section(section_name):
	next_section = section_name

func play_next_section():
	if next_section != null:
		get_node(next_section).play()
		current_section = next_section
	else:
		get_node(current_section).play()

func finished_section():
	play_next_section()
