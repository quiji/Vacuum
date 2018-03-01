extends Node2D

signal react

func _ready():
	$anim_player.play("Idle")
	$anim_player.connect("animation_finished", self, "on_animation_finished")

var current_anim = null

func play(anim):

	if $anim_player.is_playing() and current_anim == "EndRoll":
		return false
	
	if anim != current_anim:
		$anim_player.play(anim)
		current_anim = anim

	return true

func is_playing(playing=null):
	if playing == null:
		return $anim_player.is_playing()
	else:
		return playing == current_anim and $anim_player.is_playing()
	
func set_flip_h(val):
	$sprite.set_flip_h(val)
	
func react(action):
	emit_signal("react", action)

####################
#  "Personal" implementations
####################

func on_animation_finished(anim_name):
	match anim_name:
		"Swim":
			play("WaterIdle")
