extends Node

####### MUSICS #########
const ConcealedGarden = preload("res://music_director/concealed_garden/director.tscn")

enum MusicCompositions {CONCEALED_GARDEN}

const DEFAULT_MOD_BUS = 3
const WATER_MOD_BUS = 2
const OUTTER_SPACE_MOD_BUS = 1



################################################################################################
#
#                                        Music Directors
#
################################################################################################

var current_music = null
var current_composition = null
func start_music(composition):
	if current_composition == composition:
		return 

	match composition:
		CONCEALED_GARDEN:

			current_music = ConcealedGarden.instance()
			add_child(current_music)
			current_music.start()
			current_composition = composition
			
			

func music():
	return current_music

var prev_mod = DEFAULT_MOD_BUS
var current_mod = DEFAULT_MOD_BUS

func restore_default_mod():
	#AudioServer.set_bus_bypass_effects(WATER_MOD_BUS, true)
	AudioServer.set_bus_bypass_effects(OUTTER_SPACE_MOD_BUS, true)
	prev_mod = current_mod
	current_mod = DEFAULT_MOD_BUS

func activate_water_mod():
	AudioServer.set_bus_bypass_effects(OUTTER_SPACE_MOD_BUS, true)
	AudioServer.set_bus_bypass_effects(WATER_MOD_BUS, false)
	prev_mod = current_mod
	current_mod = WATER_MOD_BUS


func activate_outer_space_mod():
	AudioServer.set_bus_bypass_effects(WATER_MOD_BUS, true)
	AudioServer.set_bus_bypass_effects(OUTTER_SPACE_MOD_BUS, false)
	prev_mod = current_mod
	current_mod = OUTTER_SPACE_MOD_BUS

func restore_prev_mod():
	match prev_mod:
		OUTTER_SPACE_MOD_BUS:
			activate_outer_space_mod()
		DEFAULT_MOD_BUS:
			restore_default_mod()
		WATER_MOD_BUS:
			activate_water_mod()

	
