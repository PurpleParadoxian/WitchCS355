@tool
extends Node3D

@onready var gigaChunkHolder := $GigaChunkHolder
@onready var player := $Player

@export var playerPos: Vector3
@export var button: bool

const CHUNK_MULTIPLES = [0, 2, 2, 2, 2, 5]
const BLOCK_SCALES = [0.125, 0.125*2, 0.125*4, 0.125*8, .125*16, .125*16*5]
const gigaD := 5
const gigaDSqrd := gigaD**2
const gigaDCubd := gigaD**3

var chunk_scene = preload("res://scenes/TestChunk.tscn")

var prevPlayerBPos: Array[Vector3i]
var prevPlayerPos: Vector3

class Chunk extends Node:
	var theChunk: PackedScene
	var innerChunks: Array[Chunk]
	var c: Object
	var pos: Vector3i
	var bScale: float
	var subChunks: bool
	var mult: int
	var mult2: int
	var mult3: int
	
	func inRange(a: Vector3i, b: Vector3i) -> bool:
		var c = abs(b-a)
		return c.x <= 1 and c.y <= 1 and c.z <= 1
	
	func chunkToV(a):
		if a < 0 or a >= mult3: return null
		return Vector3i(int(a/mult2) % mult, int(a/mult) % mult, a % mult)
	
	func _init(k: int, pPos: Vector3, cPos: Vector3i, thisChunk: PackedScene):
		bScale = k
		pos = cPos
		theChunk = thisChunk
		mult = CHUNK_MULTIPLES[bScale]
		mult2 = mult*mult
		mult3 = mult2*mult
		
		if k > 0 and inRange(pPos/(BLOCK_SCALES[bScale]*Global.DIMENSION[0]), pos):
			subChunks = true
			innerChunks.resize(mult3)
			for i in range(mult3):
				innerChunks[i] = Chunk.new(k-1, pPos, chunkToV(i)+pos*mult, theChunk)
				self.add_child(innerChunks[i])
		else:
			subChunks = false
			c = theChunk.instantiate()
			c._ready()
			c.set_chunk_scale(bScale)
			c.set_chunk_position(pos)
			self.add_child(c)
	
	func changeVisibility(v: bool):
		if subChunks:
			for i in innerChunks: i.changeVisibility(v)
		else:
			c.visible = v
	
	func update(k: int, pPos: Vector3):
		if k != bScale and subChunks:
			for i in innerChunks: i.update(k, pPos)
		elif k == bScale:
			if bScale > 0 and inRange(pPos/(BLOCK_SCALES[bScale]*Global.DIMENSION[0]), pos):
				subChunks = true
				if c != null: c.visible = false
				if innerChunks.is_empty():
					innerChunks.resize(mult3)
					for i in range(mult3):
						innerChunks[i] = Chunk.new(bScale-1, pPos, chunkToV(i)+pos*mult, theChunk)
						self.add_child(innerChunks[i])
				else: 
					for i in innerChunks: i.update(k-1, pPos)
			else:
				subChunks = false
				if innerChunks != null:
					for i in innerChunks: i.changeVisibility(false)
				if c == null:
					c = theChunk.instantiate()
					c._ready()
					c.set_chunk_scale(bScale)
					c.set_chunk_position(pos)
					self.add_child(c)
				else: c.visible = true

var teraChunk: Chunk

func _ready():
	playerPos = player.position
	var theChunk = PackedScene.new()
	var c = chunk_scene.instantiate()
	add_child(c)
	c.calc()
	c.set_chunk_position(Vector3i(0, 0, 0))
	theChunk.pack(c)
	c.call_deferred("queue_free")
	
	# debug test (I mean, this whole thing is a test anyway)
	c = theChunk.instantiate()
	c.set_chunk_position(Vector3i(-2, 1, 2))
	add_child(c)
	
	teraChunk = Chunk.new(5, playerPos, Vector3i.ZERO, theChunk)
	gigaChunkHolder.add_child(teraChunk)
	
	prevPlayerBPos.resize(6)
	for i in range(6): prevPlayerBPos[i] = Vector3i( playerPos/(BLOCK_SCALES[i]*Global.DIMENSION[0]) )
	
	prevPlayerPos = playerPos

func _process(delta):
	await get_tree().create_timer(.5).timeout
	playerPos = player.position
	if playerPos != prevPlayerPos:
		for i in range(5, -1, -1):
			if prevPlayerBPos[i] != Vector3i( playerPos/(BLOCK_SCALES[i]*Global.DIMENSION[0]) ):
				teraChunk.update(i, playerPos)
				break
		for i in range(6): prevPlayerBPos[i] = Vector3i( playerPos/(BLOCK_SCALES[i]*Global.DIMENSION[0]) )
		prevPlayerPos = playerPos
