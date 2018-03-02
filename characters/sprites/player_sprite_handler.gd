extends Node2D

signal react

var timer = null
func _ready():

	$anim_player.playback_process_mode = AnimationPlayer.ANIMATION_PROCESS_PHYSICS
	$anim_player.play("Idle")
	$anim_player.connect("animation_finished", self, "on_animation_finished")
	
	timer = Timer.new()
	add_child(timer)
	timer.connect("timeout", self, "on_timeout")
	timer.one_shot = true
	timer.wait_time = 8.0
	timer.autostart = false
	

var current_anim = null
var last_orientation = false
func play(anim, back=false):

	if $anim_player.is_playing() and current_anim == "EndRoll":
		return false
		
	if anim == "Idle" and $anim_player.is_playing() and current_anim == "IdleLong":
		return false
		
	if anim != current_anim or (back != last_orientation):
		if not back:
			$anim_player.play(anim)
		else:
			$anim_player.play_backwards(anim)
		current_anim = anim
		last_orientation = back
			
		if anim == "Idle":
			timer.start()
		elif timer.time_left > 0:
			timer.stop()

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
		"IdleLong":
			play("Idle")
		"LookDown":
			continue
		"LookUp":
			if last_orientation:
				play("Idle")
				get_parent().looking = false

func on_timeout():
	play("IdleLong")
