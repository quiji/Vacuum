extends Area2D

enum TriggerTypes {PLAY, SECTION}

export (int, "PLAY", "SECTION") var trigger_type
export (String) var trigger_section
export (bool) var trigger_once 


var triggered = 0
func _ready():
	connect("body_entered", self, "trigger_music_section")

func trigger_music_section(body):
	if trigger_once and triggered > 0:
		return
	triggered +=1
	
	match trigger_type:
		PLAY:
			Glb.music().start()
		SECTION:
			Console.add_log("music_section", trigger_section)
			Glb.music().go_to_section(trigger_section)
