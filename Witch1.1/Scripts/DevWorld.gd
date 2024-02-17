@tool
extends Node3D

var chunk_scene = preload("res://chunk.tscn")

const half_radius_vector = Vector3(load_radius, load_radius, load_radius)/2
const load_radius = 1

@onready var chunks = $Chunks
@onready var player = $Player

var load_thread = Thread.new()
var player_position = Vector3()
var prev_player_position = Vector3i()
var all_chunks = {}

func _ready():
	print("start start")
	
	var call_thread = _thread_process
	load_thread.start(call_thread)
	print("thread started")
	load_thread.wait_to_finish()

func update_player_position():
	player_position = player.position

func make_new_chunk():
	var chunk_pos = player.position / Global.DIMENSION[0]
	
	print("making chunk: ", chunk_pos)
	var chunk = chunk_scene.instantiate()
	chunk.set_chunk_position(chunk_pos)
	all_chunks[chunk_pos] = chunk
	chunks.add_child(chunk)

func _thread_process():
	print("thread running")
	
	while(true):
		await get_tree().create_timer(1).timeout
		# handle block placements
