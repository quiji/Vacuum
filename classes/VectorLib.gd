extends Node

const POLY4 = [Vector2(0,-1), Vector2(1, 0), Vector2(0,1), Vector2(-1,0)]
const POLY8 = [
	Vector2(0,-1), Vector2(0.707107, -0.707107), Vector2(1, 0), 
	Vector2(0.707107, 0.707107), Vector2(0,1), Vector2(-0.707107, 0.707107), 
	Vector2(-1,0), Vector2(-0.707107, -0.707107)
]

const POLY16 = [
	Vector2(0,-1), Vector2(0.382683, -0.92388), Vector2(0.707107, -0.707107), Vector2(0.92388, -0.382683), 
	Vector2(1, 0), Vector2(0.92388, 0.382683), Vector2(0.707107, 0.707107), Vector2(0.382683, 0.92388), 
	Vector2(0,1), Vector2(-0.382683, 0.92388), Vector2(-0.707107, 0.707107), Vector2(-0.92388, 0.382683), 
	Vector2(-1,0), Vector2(-0.92388, -0.382683), Vector2(-0.707107, -0.707107), Vector2(-0.382683, -0.92388)
]


# moving! positive if to the right, negative if to the left of stationary
static func perp_prod(stationary, moving):
	return stationary.dot(moving.tangent())

static func cross_product(a, b):
	return a.x * b.y - a.y - b.x

static func vector_orientation(stationary, moving):
	var perp_p = perp_prod(stationary, moving)
	if perp_p < 0:
		return -1
	elif perp_p > 0:
		return 1
	else:
		return 0

static func snap_to(v, vects):
	
	var i = 0
	var max_dot = -1
	var max_i = -1

	while i < vects.size():
		var dot = v.dot(vects[i])
		if dot > max_dot:
			max_dot = dot
			max_i = i
		
		i += 1

	return vects[max_i]