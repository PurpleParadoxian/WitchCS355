@tool
extends Node

class_name TreeGenerator

var rn = RandomNumberGenerator.new()
const gold = 2.3999632297

@export var limbs : Array[Vector4]

@export var limbDepth: int
@export var limbLMeans: Array[float]
@export var limbLVariances: Array[float]
@export var limbNMeans: Array[float]
@export var limbNVariances: Array[float]
@export var limbPMeans: Array[float]
@export var limbPVariances: Array[float]

@export var visualize := false : set = set_visualize
func set_visualize(new_value: bool)->void: print("from tool")

func _init(limbDepth: int, limbLMeans: Array[float], limbLVariances: Array[float], limbNMeans: Array[float], limbNVariances: Array[float], limbPMeans: Array[float], limbPVariances: Array[float]):
	self.limbDepth = limbDepth
	self.limbLMeans = limbLMeans
	self.limbLVariances = limbLVariances
	self.limbNMeans = limbNMeans
	self.limbNVariances = limbNVariances
	self.limbPMeans = limbPMeans
	self.limbPVariances = limbPVariances

func _process(delta):
	if visualize:
		visualizeNewTree()
		visualize = false

func getNewTree() -> Array[Vector4]:
	newTree()
	return limbs

func newTree():
	for i in range(limbDepth):
		pass

func newBranch(prevBranch, pos):
	pass

func Vec4Vec3(v: Vector4) -> Vector3:
	return Vector3(v.x, v.y, v.z)

func visualizeNewTree():
	if limbs == null: newTree()
	var vectorList: Array[Vector3] = []
	var parPos := Vector3.ZERO
	var parent := Vector3.ZERO
	
	for i in limbs:
		if i == Vector4.ZERO:
			parent = vectorList.pop_back()
			parPos -= parent
			continue
		var w = i.w
		var p = Vec4Vec3(i)
		var start = parPos+parent.normalized()*w
		DebugDraw3D.draw_line(start, start+p)
		vectorList.push_back(parent)
		parPos += parent
		parent = p
