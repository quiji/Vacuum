

static func start2(t): return t * t
static func start3(t): return t * t * t
static func start4(t): return t * t * t * t
static func start5(t): return t * t * t * t * t
static func start6(t): return t * t * t * t * t * t
static func start7(t): return t * t * t * t * t * t * t

static func stop2(t): return 1 - (1 - t) * (1 - t) 
static func stop3(t): return 1 - (1 - t) * (1 - t) * (1 - t) 
static func stop4(t): return 1 - (1 - t) * (1 - t) * (1 - t) * (1 - t) 
static func stop5(t): return 1 - (1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t) 
static func stop6(t): return 1 - (1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t) 
static func stop7(t): return 1 - (1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t) 

static func flip(t): return 1 - t

static func blend(t, smootha, smoothb, weight): return (1 - weight) * smootha + weight * smoothb
static func cross(t, smootha, smoothb): return blend(t, smootha, smoothb, t)

static func scale(t, smootha): return t * smootha
static func rev_scale(t, smootha): return (1 - t) * smootha

static func arch(t, w=1): return scale(t * w, flip(t))

static func linear_interp(a, b, t):
	return a + (b - a) * t

static func radial_interpolate(a, b, t):
	var dot = a.dot(b)
	var res
	
	if dot >= 0:
		res = linear_interp(a, b, t)
	elif dot >= -0.5:
		var half = (a + b)/2
		res = cross(t, linear_interp(a, half, t), linear_interp(half, b, t))
	else:
		var half = b.tangent()
		half = half * (1 if a.dot(half) > 0 else -1)
		res = cross(t, linear_interp(a, half, t), linear_interp(half, b, t))
	
	return res.normalized()





static func graph(owner, method, size=150, offset=Vector2(), step=0.01):
	var points = PoolVector2Array()
	
	var t = 0
	while t < 1:
		points.append(Vector2(t * size, -owner.call(method, t) * size) + offset)
		t += step
	
	return points


#######################################
# Personal Lib

static func water_out(t):
	return cross(t, stop2(t), flip(arch(t, 5)))

static func water_entrance_rotation(t):
	return cross(t, stop2(t), flip(arch(t, 2.8)))

static func water_in_pivot(t):
	return cross(t, start3(stop3(t)), stop3(start3(t)))

static func water_in(t):
	return cross(t, stop6(t), flip(arch(t)))

static func water_resistance_on_edges(t):
	return scale(t, start6(t))

static func swim_stroke(t):
	return stop6(start4(t))

static func water_resistance(t):
	return clamp(flip(cross(t, start2(t), start6(t))), 0, 0.7)

static func run_step(t):
	return arch(start2(t), 1.5) + 0.66

static func cam_space_mov(t):
	return stop3(start2(t))

static func cam_space_path(t):
	return cross(t, stop2(t), flip(arch(t, 2)))

static func cam_water_mov(t):
	return stop6(start2(t))

static func cam_circular_full_rot(t):
	return start5(stop4(t))

static func cam_circular_small_rot(t):
	return scale(t, stop2(t))

static func cam_circular_rot(t, d):
	return blend(t, cam_circular_small_rot(t), cam_circular_full_rot(t), d)

static func test(t):
	return cross(t, start2(t), start6(t))

#	return arch(t, 4)

