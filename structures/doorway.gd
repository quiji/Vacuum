extends KinematicBody2D


var position_y

func _ready():
	position_y = $sprite.position.y
	$open_area.connect("body_entered", self, "on_body_entered")
	$open_area.connect("body_exited", self, "on_body_exited")


func on_body_entered(body):
	$tween.interpolate_method(self, "open_door", 0, 1, 0.55, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$tween.start()

func on_body_exited(body):
	$tween.interpolate_method(self, "open_door", 1, 0, 0.55, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	$tween.start()
	

func open_door(t):
	$sprite.position.y = position_y - position_y * t * 2
	$collision.position.y = - position_y * t * 2
