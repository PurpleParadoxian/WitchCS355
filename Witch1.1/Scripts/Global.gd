extends Node

const BLOCK_SCALE = 0.125
const DIMENSION = Vector3(64, 64, 64)
const TEXTURE_ATLAS_SIZE = Vector2(3, 2)
const FACE_SIDES = [
	Vector3(0, 1, 0),  Vector3(0, -1, 0),
	Vector3(-1, 0, 0), Vector3(1, 0, 0),
	Vector3(0, 0, 1),  Vector3(0, 0, -1)
]
const faces = [
	[2, 3, 7, 6],
	[0, 4, 5, 1],
	[6, 4, 0, 2],
	[3, 1, 5, 7],
	[7, 5, 4, 6],
	[2, 0, 1, 3]
]
const vertices = [
	Vector3(0, 0, 0),
	Vector3(1, 0, 0),
	Vector3(0, 1, 0),
	Vector3(1, 1, 0),
	Vector3(0, 0, 1),
	Vector3(1, 0, 1),
	Vector3(0, 1, 1),
	Vector3(1, 1, 1)
]

enum {
	TOP,
	BOTTOM,
	LEFT,
	RIGHT,
	FRONT,
	BACK,
	SOLID,
	COLOR,
}

enum {
	AIR,
	DIRT,
	GRASS,
	STONE
}

const types = {
	AIR:{
		SOLID:false
	},
	DIRT:{
		COLOR:Color("BROWN"),
		SOLID:true
	},
	GRASS:{
		COLOR:Color("LIGHT_GREEN"),
		SOLID:true
	},
	STONE:{
		COLOR:Color(150, 150, 150),
		SOLID:true
	}
}

func modVector3(a, b):
	return Vector3(a[0] % b, a[1] % b, a[2] % b)
