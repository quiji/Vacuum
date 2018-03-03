

static func start2(t): return t * t
static func start3(t): return t * t * t
static func start4(t): return t * t * t * t
static func start5(t): return t * t * t * t * t
static func start6(t): return t * t * t * t * t * t

static func stop2(t): return 1 - (1 - t) * (1 - t) 
static func stop3(t): return 1 - (1 - t) * (1 - t) * (1 - t) 
static func stop4(t): return 1 - (1 - t) * (1 - t) * (1 - t) * (1 - t) 
static func stop5(t): return 1 - (1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t) 
static func stop6(t): return 1 - (1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t) * (1 - t) 

static func flip(t): return 1 - t

static func blend(t, smootha, smoothb, weight): return (1 - weight) * smootha + weight * smoothb
static func cross(t, smootha, smoothb): return blend(t, smootha, smoothb, t)

static func scale(t, smootha): return t * smootha
static func rev_scale(t, smootha): return (1 - t) * smootha

static func arch(t, w=1): return scale(t * w, flip(t))

static func linear_interp(a, b, t):
	return a + (b - a) * t


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
	return stop6(start5(t))
	return cross(t, stop6(start5(t)), start5(stop6(t)))

static func test(t):
	return arch(t, 4)

