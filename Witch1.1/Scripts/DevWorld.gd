extends Node3D

var chunk_scene = preload("res://chunk.tscn")

const half_radius_vector = Vector3(load_radius, load_radius, load_radius)/2
const load_radius = 1

@onready var chunks = $Chunks
@onready var player = $Player
@onready var info : Label = $Player/Head/HUD/Info

var newBlocksMut = Mutex.new()
var newBlocks = []
var load_thread = Thread.new()
var player_position = Vector3()
var prev_player_position = Vector3i()
var all_chunks = {}
var filename : String
var devMode : bool

func getInfo(a):
	filename = a[0]
	devMode = a[1]
	start()

func start():
	print("start start")
	
	player.doThing(self)
	
	var call_thread = _dev_thread_process if devMode else _thread_process
	load_thread.start(call_thread)
	print("thread started")
	load_thread.wait_to_finish()

func strToVec3(a):
	var b = a.split(",")
	return Vector3i(b[0], b[1], b[2])

func update_player_position():
	player_position = player.position

func place_new_block(a : Vector3i, b : Vector3i, c: int):
	newBlocksMut.lock()
	newBlocks.push_back([a, b, c])
	newBlocksMut.unlock()

func _thread_process():
	pass

func _dev_thread_process():
	print("dev thread running")
	info.text = "loading premade chunks"
	if filename != "New":
		var file = FileAccess.open("user://builtLevels/" + filename, FileAccess.READ)
		var content = file.get_as_text().split("\n")
		for chk in content:
			var ch = chk.split(":")
			var c = strToVec3(ch[0])
			var chunk = chunk_scene.instantiate()
			chunk.set_chunk_position(c)
			all_chunks[c] = chunk
	info.text = ""
	
	while(true):
		await get_tree().create_timer(1).timeout
		
		# handle block placements
		while not newBlocks.is_empty():
			newBlocksMut.lock()
			var a = newBlocks.pop_front()
			newBlocksMut.unlock()
			
			if not all_chunks.contains(a[0]): # make a new chunk if player tries to place a block where one doesn't exist
				info.text = "making new chunk: " + a[0]
				var chkPos = a[0]
				var chunk = chunk_scene.instantiate()
				chunk.set_chunk_position(chkPos)
				chunk.calc()
				all_chunks[chkPos] = chunk
				chunks.add_child(chunk)
			var chunk = all_chunks[a[0]]
			var blkPos = a[1]
			var type = a[2]
			info.text = "placing block: " + blkPos + "\nin Chunk: " + a[0]
			
			chunk.place_block(blkPos, type)
			
			info.text = ""
