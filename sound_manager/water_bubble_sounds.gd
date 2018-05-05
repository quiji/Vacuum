extends Node2D

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	$water_ambience.volume_db = -80
	$water_ambience2.volume_db = -80
	$tween.connect("tween_completed", self, "on_tween_completed")

func dive_in():
	$dive_in.play()

	$water_ambience.play()
	$water_ambience2.play(0.8)
	$tween.interpolate_property($water_ambience, "volume_db", $water_ambience.volume_db, -15, 0.15, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$tween.interpolate_property($water_ambience2, "volume_db", $water_ambience.volume_db, -15, 0.15, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$tween.start()

func dive_out():
	$tween.interpolate_property($water_ambience, "volume_db", -15, -80, 0.15, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$tween.interpolate_property($water_ambience2, "volume_db", -15, -80, 0.15, Tween.TRANS_LINEAR, Tween.EASE_IN)
	$tween.start()
	$dive_in.play()

func on_tween_completed(obj, prop):
	if obj == $water_ambience and $water_ambience.volume_db == -80:
		$water_ambience.stop()
	elif obj == $water_ambience2 and $water_ambience2.volume_db == -80:
		$water_ambience2.stop()

