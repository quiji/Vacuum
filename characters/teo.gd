extends Node2D


var current_anim = null



func play(anim):

	if $anim.is_playing() and current_anim == "r-EndRoll":
		return false
	
	if anim != current_anim:
		$anim.play(anim)
		current_anim = anim
		#Console.l("current_anim", anim)

	return true

func is_playing(playing=null):
	if playing == null:
		return $anim.is_playing()
	else:
		return playing == current_anim and $anim.is_playing()
	
	