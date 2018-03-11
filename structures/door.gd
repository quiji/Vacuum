extends Area2D

export (String) var target_stage = ''
export (String) var door_id = ''


func _ready():
	add_to_group("doors")
	connect("body_entered", self, "on_body_entered")
	connect("body_exited", self, "on_body_exited")


func on_body_entered(body):
	body.on_door(self)

func on_body_exited(body):
	body.off_door()

func enter():
	get_parent().get_parent().fade_towards(target_stage, door_id)

