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
		TOP:Vector2(2, 0), BOTTOM:Vector2(2, 0), LEFT: Vector2(2, 0),
		RIGHT:Vector2(2, 0), FRONT:Vector2(2, 0), BACK: Vector2(2, 0),
		SOLID:true
	},
	GRASS:{
		TOP:Vector2(0, 0), BOTTOM:Vector2(2, 0), LEFT: Vector2(1, 0),
		RIGHT:Vector2(1, 0), FRONT:Vector2(1, 0), BACK: Vector2(1, 0),
		SOLID:true
	},
	STONE:{
		TOP:Vector2(0, 1), BOTTOM:Vector2(0, 1), LEFT: Vector2(0, 1),
		RIGHT:Vector2(0, 1), FRONT:Vector2(0, 1), BACK: Vector2(0, 1),
		SOLID:true
	}
}

