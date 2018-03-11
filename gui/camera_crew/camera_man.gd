extends Camera2D

var actions = []

func _ready():
	current = true
	rotating = true
	drag_margin_h_enabled = false
	drag_margin_v_enabled = false
	smoothing_enabled = false

func add_action(action):
	actions.push_back(action)

func camera_start_action(action):
	action.t = 0
	action.on = true
	action.start_position = action.current_position

func camera_interrupt(action):
	action.start_position = action.current_position

func camera_is_action_completed(action):
	return action.on and action.t == null

func camera_end_action(action):
	action.t = 0
	action.on = false
	action.start_position = action.current_position
	action.target = Vector2()


func camera_do_action(action, delta):
	if action.t < 1:
		Console.add_log("working_on", action)
		action.current_position = action.start_position.linear_interpolate(action.target, Glb.Smooth.call(action.method, action.t))
		action.t += delta / action.duration
	else:
		action.t = null


func _physics_process(delta):
	
	var final_pos = Vector2()
	var i = 0
	while i < actions.size():
		if actions[i].t != null:
			camera_do_action(actions[i], delta)
		final_pos += actions[i].current_position
		i += 1

	position = final_pos

