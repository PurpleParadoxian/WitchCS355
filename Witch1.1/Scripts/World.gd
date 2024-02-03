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
	for i in range(-load_radius, load_radius+1):
		for j in range(-load_radius, load_radius+1):
			for k in range(-load_radius, load_radius+1):
				var chunk_pos = Vector3(i, j, k)
				print("starting chunk: ", chunk_pos)
				var chunk = chunk_scene.instantiate()
				chunk.set_chunk_position(chunk_pos)
				all_chunks[chunk_pos] = chunk
				chunks.add_child(chunk)
	"""var i = 0
	var k = 0
	for j in range(-1, 2):
		var chunk_pos = Vector3(i, j, k)
		print("starting chunk: ", chunk_pos)
		var chunk = chunk_scene.instantiate()
		chunk.set_chunk_position(chunk_pos)
		all_chunks[chunk_pos] = chunk
		chunks.add_child(chunk)""" # debug
	
	#self.add_child(t)
	#t.set_wait_time(2)
	#t.start()
	var call_thread = _thread_process
	load_thread.start(call_thread)
	print("thread started")
	load_thread.wait_to_finish()

func update_player_position():
	player_position = player.position

func _thread_process():
	print("thread running")
	prev_player_position = floor(player_position/(Global.BLOCK_SCALE*Global.DIMENSION))
	while(true):
		await get_tree().create_timer(1).timeout
		update_player_position.call_deferred()
		var pPos = floor(player_position/(Global.BLOCK_SCALE*Global.DIMENSION))
		if pPos == prev_player_position: continue
		else: print("we need to move")
		print("pPos ", pPos)
		# player has moved chunks
		
		# make a list of all chunks that need to be made
		var needChunks = []

		for i in range(-load_radius+pPos[0], load_radius+pPos[0]+1):
			for j in range(-load_radius+pPos[1], load_radius+pPos[1]+1):
				for k in range(-load_radius+pPos[2], load_radius+pPos[2]+1):
					var tryPos = Vector3(i, j, k)
					if not all_chunks.has(tryPos): needChunks += [tryPos]
		"""for j in range(-1+pPos[1], 2+pPos[1]):
			var tryPos = Vector3(0+pPos[0], j, pPos[2])
			if not all_chunks.has(tryPos): needChunks += [tryPos]""" # debug
		print(needChunks)
		# reassign all chunks out of the range to an available needChunk
		#var maxChunkPos = Vector3(load_radius, load_radius, load_radius)
		for k in all_chunks.duplicate():
			
			"""if k.x == pPos.x and k.z == pPos.z:
				if abs(pPos.y-k.y) <= 1: 
					print("continued on ", k)
					continue"""# debug
			var rel = abs(k-pPos)
			var cont = true
			for i in range(3):
				if rel[i] > load_radius:
					cont = false
					break
			if cont: continue # if chunk is already in the new range, skip
			
			var newPos = needChunks.pop_back()
			if newPos == null: 
				print("sonething went wronggggg..")
				break
			var c = all_chunks[k]
			# TODO: most of reassign chunks needs to be done by the thread
			c.set_chunk_position.call_deferred(newPos)
			#c.generate()
			#c.build()
			#c.update()
			all_chunks.erase(k)
			all_chunks[newPos] = c
			needChunks
		prev_player_position = pPos
