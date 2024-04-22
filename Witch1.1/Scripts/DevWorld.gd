extends Node3D

var chunk_scene = preload("res://chunk.tscn")

const half_radius_vector = Vector3(load_radius, load_radius, load_radius)/2
const load_radius = 1

@onready var chunks = $Chunks
@onready var player = $Player
@onready var info : Label = $Player/Head/HUD/Info
@onready var saveButton : Button = $Player/Head/HUD/SaveNode/SaveButton
@onready var saveName : TextEdit = $Player/Head/HUD/SaveNode/SaveTextEdit

var savePlease = 0
var load_thread = Thread.new()
var player_position = Vector3()
var prev_player_position = Vector3i()
var all_chunks = {}
var filename
var devMode : bool

var newBlocksMut = Mutex.new()
var newBlocks = []
var newBlocksRangeMut = Mutex.new()
var newBlocksRange = []
var preChunks = {}
var herring

func getInfo(a):
	print("getInfo ", a)
	filename = a[0]
	devMode = a[1]
	start()

func start():
	print("start start" + str(devMode))
	var call_thread
	if devMode: call_thread = _dev_thread_process
	else: 
		call_thread = _thread_process
		herring = load("res://scenes/WorldGen.tscn").instantiate()
		var b1 = Time.get_unix_time_from_system()
		herring.doTheBuilding()
		var b2 = Time.get_unix_time_from_system()
		loadAllPreChunks(getUniques(herring.builtRooms))
		var b3 = Time.get_unix_time_from_system()
		
		print("t1: ", b2-b1, ", t2: ", b3-b2)
	load_thread.start(call_thread)
	print("thread started")
	#load_thread.wait_to_finish()

func _ready():
	saveButton.pressed.connect(_on_save_button_pressed)
	player.placeBlocks.connect(place_new_block)
	player.placeRange.connect(place_new_block_range)

func place_new_block_range(a : Vector3i, b : Vector3i, r1 : Vector3i, r2 : Vector3i, c: int):
	print("placing " + Global.BLOCK_NAME_LIST[c])
	newBlocksRangeMut.lock()
	newBlocksRange.push_back([a, b, r1, r2, c])
	print(newBlocksRange)
	newBlocksRangeMut.unlock()

func place_new_block(a : Vector3i, b : Vector3i, c: int):
	print("placing " + Global.BLOCK_NAME_LIST[c])
	newBlocksMut.lock()
	newBlocks.push_back([a, b, c])
	print(newBlocks)
	newBlocksMut.unlock()

func getUniques(a):
	var dic = {}
	for i in a:
		dic[i] = 0
	dic.erase(255)
	return dic.keys()

func loadAllPreChunks(a):
	var file = FileAccess.open("res://builtChunks.txt", FileAccess.READ)
	var content = file.get_as_text().split("\n")
	for i in a:
		preChunks[i] = PackedScene.new()
		
		var chunk = chunk_scene.instantiate()
		chunk._ready()
		chunk.calc(content[i])
		preChunks[i].pack(chunk)
		chunk.call_deferred("queue_free")

func strToVec3(a):
	var b = a.split(",")
	return Vector3i(int(b[0]), int(b[1]), int(b[2]))

func toVCount(a):
	if a < 0 or a >= herring.boundcub: return null
	var z = a % herring.bound
	var y = int(a/herring.bound) % herring.bound
	var x = int(a/herring.boundsqr) % herring.bound
	return Vector3i(x, y, z)

func update_player_data():
	player_position = player.position
	# add player direction detection

func _setInfoText(a):
	info.text = a

func _thread_process():
	
	#loadAllPreChunks(getUniques(herring.builtRooms))
	
	var count = 0
	# this will recursiely add the other rooms in a grid fashion
	while count < herring.boundcub:
		if count%herring.boundsqr==0: print(float(count)/herring.boundcub*100,"%")
		var built = herring.builtRooms[count]
		if built == 255: 
			count+=1
			continue
		
		var c = toVCount(count)
		var chunk = preChunks[built].instantiate()
		chunk.set_chunk_position(c)
		#print("doing ", c, ", faces: ", len(chunk.faceList), ", meshIns: ", chunk.mesh_instance)
		#chunk.rotat(herring.buildRotat[count]) rotating doesn't work yet
		add_child.call_deferred(chunk)
		all_chunks[c] = chunk
		count+=1

var blkToText = ["a", "d", "g", "s"]

func _dev_thread_process():
	print("dev thread running")
	_setInfoText.call_deferred("loading premade chunks")
	if filename != "New":
		var file = FileAccess.open("user://builtLevels/" + filename, FileAccess.READ)
		var content = file.get_as_text()
		print(content)
		var chunk = chunk_scene.instantiate()
		chunk.set_chunk_position(Vector3i.ZERO)
		chunk._ready()
		chunk.calc(content)
		add_child.call_deferred(chunk)
		all_chunks[Vector3i.ZERO] = chunk
	_setInfoText.call_deferred("")
	
	while(true):
		update_player_data.call_deferred()
		await get_tree().create_timer(.25).timeout
		
		if savePlease > 0:
			var pos = Vector3i(player_position/64)
			if not all_chunks.has(pos): 
				print("there is no chunk there")
				break
			var chunk = all_chunks[pos]
			var saveString = chunk.saveChunk()
			
			var file = FileAccess.open("user://builtLevels/" + saveName.text, FileAccess.WRITE)
			if file == null: 
				savePlease -= 1
				printerr("failed cause ", FileAccess.get_open_error())
				continue
			
			file.store_buffer(saveString.to_ascii_buffer())
			savePlease -= 1
		
		# handle block placements
		while not newBlocks.is_empty():
			newBlocksMut.lock()
			var a = newBlocks.pop_front()
			newBlocksMut.unlock()
			
			if not all_chunks.has(a[0]): # make a new chunk if player tries to place a block where one doesn't exist
				print("made new chunk " + str(a[0]))
				_setInfoText.call_deferred("making new chunk: " + str(a[0]))
				var chkPos = a[0]
				var newChunk = chunk_scene.instantiate()
				newChunk.set_chunk_position(chkPos)
				newChunk.calc()
				all_chunks[chkPos] = newChunk
				chunks.add_child(newChunk)
			var chunk = all_chunks[a[0]]
			var blkPos = a[1]
			var type = a[2]
			_setInfoText.call_deferred("placing block: " + str(blkPos) + "\nin Chunk: " + str(a[0]))
			
			chunk.place_block(blkPos, type)
			chunk.update()
			
			_setInfoText.call_deferred("")
		
		while not newBlocksRange.is_empty():
			newBlocksRangeMut.lock()
			var a = newBlocksRange.pop_front()
			newBlocksRangeMut.unlock()
			
			var c  : Vector3i = a[0]
			var p  : Vector3i = a[1]
			var r1 = p+a[2]
			var r2 = p+a[3]
			
			var tc : Vector3i = Vector3i(c)
			
			for i in range(p[0]+r1[0], p[0]+r2[0]+1):
				tc[0] += floor(i/64)
				i = i%64
				
				for j in range(p[1]+r1[1], p[1]+r2[1]+1):
					tc[1] += floor(j/64)
					j = j%64
					
					for k in range(p[2]+r1[2], p[2]+r2[2]+1):
						tc[2] += floor(k/64)
						k = k%64
						
						if not all_chunks.has(tc): # make a new chunk if player tries to place a block where one doesn't exist
							print("made new chunk " + str(tc))
							_setInfoText.call_deferred("making new chunk: " + str(tc))
							var newChunk = chunk_scene.instantiate()
							newChunk.set_chunk_position(tc)
							newChunk.calc()
							all_chunks[tc] = newChunk
							chunks.add_child(newChunk)
						
						var chunk = all_chunks[tc]
						var bPos = Vector3i(i, j, k)
						chunk.place_block(bPos, a[4])
						chunk.update()
		
		#for c in all_chunks: all_chunks[c].update()

func _on_save_button_pressed():
	print("a")
	savePlease += 1
