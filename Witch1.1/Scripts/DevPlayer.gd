extends CharacterBody3D

@onready var head : Node3D = $Head
@onready var camera : Camera3D = $Head/Camera
@onready var cast : RayCast3D = $Head/RayCast3D
@onready var collShape : CollisionShape3D = $COLLISION
@onready var boxShow : MeshInstance3D = $SelectedBlockMesh
@onready var lookAt : Label = $Head/HUD/LookingAt
@onready var itemNm : Label = $Head/HUD/ItemName
@onready var matNm : Label = $Head/HUD/MaterialName	

const movement_speed = 10
const jump_velocity = 10
const mouse_sensitivity = 0.3
const itemList = ["float", "replace", "place"]

var parentScript

var materialI = 0
var itemI = 0
var camera_x_rotation = 0
var paused = false
var god = true
var gravity = 20

func doThing(a):
	parentScript = a

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	boxShow.transform = boxShow.transform.scaled(Vector3(Global.BLOCK_SCALE, Global.BLOCK_SCALE, Global.BLOCK_SCALE))
	matNm.text = Global.BLOCK_NAME_LIST[materialI]
	itemNm.text = itemList[itemI]

func _input(event):
	if Input.is_action_just_pressed("Pause"):
		paused = not paused
		if paused: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if paused: return
	
	if Input.is_action_just_pressed("SwapItem"):
		itemI += 1
		if itemI == itemList.size(): itemI = 0
		itemNm.text = itemList[itemI]
	
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
	if itemI == 0:
		boxShow.position = (-my_basis.z/Global.BLOCK_SCALE).floor()
	
	if Input.is_action_just_pressed("Place"):
		var chunkPos
		var inChunkPos
		if itemI == 0:
			var blockPos = position-my_basis.z/Global.BLOCK_SCALE
			chunkPos = Vector3i(blockPos/Global.DIMENSION)
			inChunkPos = Vector3i(position.posmodv(Global.DIMENSION))
		"""
		elif itemI == 2 and cast.is_colliding():
			var colPoint = cast.get_collision_point()
			var colNorma = cast.get_collision_normal()
			var globalPos = (colPoint/Global.BLOCK_SCALE - colNorma/2).floor()
			chunkPos = Vector3i(globalPos/Global.DIMENSION)
			inChunkPos = Vector3i(globalPos.posmodv(Global.DIMENSION))
			var showBlockPos = (colPoint + colNorma/(2*Global.BLOCK_SCALE)).floor() - position
			boxShow.position = showBlockPos
			lookAt.text = "Chunk: " + chunkPos + "\nPos: " + inChunkPos"""
		parentScript.place_new_block(chunkPos, inChunkPos, materialI)
		
