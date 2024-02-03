extends CharacterBody3D

@onready var head = $Head
@onready var camera = $Head/Camera

const movement_speed = 10
const jump_velocity = 10
const mouse_sensitivity = 0.3

var camera_x_rotation = 0
var paused = false
var god = true
var gravity = 20

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event):
	if Input.is_action_just_pressed("Pause"):
		paused = not paused
		if paused: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	if paused: return
	
	if Input.is_action_just_pressed("God"):
		god = not god
	
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
	
	velocity.x = direction.x * movement_speed
	velocity.z = direction.z * movement_speed
	
	if not god:
		if Input.is_action_just_pressed("Jump") and is_on_floor():
			velocity.y = jump_velocity
		velocity.y -= gravity*delta
	move_and_slide()
