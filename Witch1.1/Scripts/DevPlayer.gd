extends CharacterBody3D

@onready var head : Node3D = $Head
@onready var camera : Camera3D = $Head/Camera
@onready var cast : RayCast3D = $Head/Camera/RayCast3D
@onready var collShape : CollisionShape3D = $COLLISION
@onready var boxShow : MeshInstance3D = $SelectedBlockMesh
@onready var lookAt : Label = $Head/HUD/LookingAt
@onready var itemNm : Label = $Head/HUD/ItemName
@onready var matNm : Label = $Head/HUD/MaterialName
@onready var saveNd : Node2D = $Head/HUD/SaveNode

const movement_speed = 4
const jump_velocity = 10
const mouse_sensitivity = 0.3
const itemList = ["float", "replace", "place"]

var newBlocksMut = Mutex.new()
var newBlocks = []

var materialI = 0
var itemI = 0
var camera_x_rotation = 0
var paused = false
var god = true
var gravity = 20

func lessThanV(v, a):
	return v.x<a or v.y<a or v.z<a

func posModV(v: Vector3i, mod):
	return Vector3i(posmod(v.x, mod), posmod(v.y, mod), posmod(v.z, mod))

func place_new_block(a : Vector3i, b : Vector3i, c: int):
	print("placing " + Global.BLOCK_NAME_LIST[c])
	newBlocksMut.lock()
	newBlocks.push_back([a, b, c])
	print(newBlocks)
	newBlocksMut.unlock()

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	boxShow.transform = boxShow.transform.scaled(Vector3(Global.BLOCK_SCALE, Global.BLOCK_SCALE, Global.BLOCK_SCALE))
	matNm.text = Global.BLOCK_NAME_LIST[materialI]
	itemNm.text = itemList[itemI]
	collShape.disabled = god

func _input(event):
	if Input.is_action_just_pressed("Pause"):
		paused = not paused
		if paused: 
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		saveNd.visible = paused
	
	if paused: return
	
	if Input.is_action_just_pressed("SwapItem"):
		itemI += 1
		if itemI == itemList.size(): itemI = 0
		itemNm.text = itemList[itemI]
		lookAt.text = ""
	
	if Input.is_action_just_pressed("SwapMat"):
		materialI += 1
		if materialI == Global.BLOCK_NAME_LIST.size(): materialI = 0
		matNm.text = Global.BLOCK_NAME_LIST[materialI]
	
	if Input.is_action_just_pressed("God"):
		god = not god
		collShape.disabled = god
	
	if event is InputEventMouseMotion:
		head.rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		
		var delta_x = event.relative.y * mouse_sensitivity
		
		if camera_x_rotation + delta_x > -90 and camera_x_rotation + delta_x < 90:
			camera.rotate_x(deg_to_rad(-delta_x))
			camera_x_rotation += delta_x

func _physics_process(delta):
	if paused: return
	var my_basis = head.global_transform.basis
	var direction = Vector3()
	
	if Input.is_action_pressed("Forward"):
		direction -= my_basis.z
	if Input.is_action_pressed("Back"):
		direction += my_basis.z
	if Input.is_action_pressed("Left"):
		direction -= my_basis.x
	if Input.is_action_pressed("Right"):
		direction += my_basis.x
	
	if god:
		if Input.is_action_pressed("Jump"):
			direction += my_basis.y
		if Input.is_action_pressed("Descend"):
			direction -= my_basis.y
		velocity.y = direction.y * movement_speed
	else:
		if Input.is_action_just_pressed("Jump") and is_on_floor():
			velocity.y = jump_velocity
		velocity.y -= gravity*delta
	
	velocity.x = direction.x * movement_speed
	velocity.z = direction.z * movement_speed
	move_and_slide()
	
	# place and break blocks
	var cam_basis = camera.global_transform.basis
	var chunkPos
	var inChunkPos
	var showBlockPos = null
	if itemI == 0:
		var blockGlobalPos = position-cam_basis.z+cam_basis.y/2
		var blockWorldPos = Vector3i(blockGlobalPos/Global.BLOCK_SCALE)
		chunkPos = blockWorldPos/Global.DIMENSION
		inChunkPos = posModV(blockWorldPos, Global.DIMENSION[0])
		print(blockWorldPos, " ", chunkPos, " ", inChunkPos)
		showBlockPos = (Vector3(blockWorldPos) + Vector3.ONE/2)*Global.BLOCK_SCALE - position
	elif itemI in [1,2] and cast.is_colliding():
		var colPoint = cast.get_collision_point()
		var colNorma = cast.get_collision_normal()
		var blockWorldPos = Vector3i(colPoint/Global.BLOCK_SCALE + colNorma/2 * (-1 if itemI==1 else 1))
		chunkPos = blockWorldPos/Global.DIMENSION
		inChunkPos = posModV(blockWorldPos, Global.DIMENSION[0])
		showBlockPos = (Vector3(blockWorldPos) + Vector3.ONE/2)*Global.BLOCK_SCALE - position
		boxShow.position = showBlockPos
		lookAt.text = "Chunk: " + str(chunkPos) + "\nPos: " + str(inChunkPos)
	elif itemI in [1,2]:
		lookAt.text = "NONE"
		showBlockPos = null
		inChunkPos = null
	
	if showBlockPos == null: boxShow.visible = false
	else:
		boxShow.visible = true
		boxShow.position = showBlockPos
	
	if Input.is_action_just_pressed("Place") and inChunkPos != null:
		place_new_block(chunkPos, inChunkPos, materialI)
		
