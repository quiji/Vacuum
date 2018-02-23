extends Node

onready var root = get_tree().get_root()
#onready var base_size = root.get_size()

# 320x180 
# 400x225 (Based on Shovel Kinght's res to fit 16:9)
# 480x270 (Based on Hyper Light Drifter's res)
# 640x360 

#var base_size = Vector2(320, 180)
#var base_size = Vector2(400, 225)
#var base_size = Vector2(480, 270)
var base_size = Vector2(640, 360)
var debug_mode = false


func _ready():
	
	root.set_size_override_stretch(false)
	root.set_size_override(false, Vector2())
	
	#root.set_as_render_target(true)
	
	root.set_update_mode(root.UPDATE_ALWAYS)
	
	#root.set_render_target_to_screen_rect(root.get_rect())
	root.set_attach_to_screen_rect(root.get_visible_rect())
	
	if not debug_mode:
		OS.set_window_resizable(false)
		OS.set_borderless_window(true)
		OS.set_window_size(OS.get_screen_size())
		OS.set_window_maximized(true)
		OS.set_window_fullscreen(true)

	scale_screen()


func scale_screen():
	var new_window_size = OS.get_window_size()
	OS.set_window_size(Vector2(max(base_size.x, new_window_size.x), max(base_size.y, new_window_size.y)))
	
	var scale_w = max(int(new_window_size.x / base_size.x), 1)
	var scale_h = max(int(new_window_size.y / base_size.y), 1)
	var scale = min(scale_w, scale_h)
	
	var diff = new_window_size - (base_size * scale)
	var diffhalf = (diff * 0.5).floor()
	
	#root.set_rect(Rect2(Vector2(), base_size))
	root.set_size(base_size)
	
	#root.set_render_target_to_screen_rect(Rect2(diffhalf, base_size * scale))
	root.set_attach_to_screen_rect(Rect2(diffhalf, base_size * scale))
	
    # Black bars aren't needed, it already renders black outside of the viewport.
	var odd_offset = Vector2(int(new_window_size.x) % 2, int(new_window_size.y) % 2)
	VisualServer.black_bars_set_margins(diffhalf.x, diffhalf.y, diffhalf.x + odd_offset.x, diffhalf.y + odd_offset.y)
	
func get_base_size():
	return base_size