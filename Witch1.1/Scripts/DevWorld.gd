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
var filename : String
var devMode : bool

var newBlocksMut = Mutex.new()
var newBlocks = []
var newBlocksRangeMut = Mutex.new()
var newBlocksRange = []

func getInfo(a):
	print("getInfo ", a)
	filename = a[0]
	devMode = a[1]
	start()

func start():
	print("start start" + str(devMode))
	
	var call_thread = _dev_thread_process if devMode else _thread_process
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

func strToVec3(a):
	var b = a.split(",")
	return Vector3i(int(b[0]), int(b[1]), int(b[2]))

func update_player_position():
	player_position = player.position

func _setInfoText(a):
	info.text = a

func _thread_process():
	pass

var blkToText = ["a", "d", "g", "s"]

func _dev_thread_process():
	print("dev thread running")
	_setInfoText.call_deferred("loading premade chunks")
	if filename != "New":
		var file = FileAccess.open("user://builtLevels/" + filename, FileAccess.READ)
		var content = file.get_as_text().split("\n")
		print(content)
		for chk in content:
			if len(chk) < 1: break
			var ch = chk.split(":")
			var c = strToVec3(ch[0])
			print("chunk Pos ", c)
			var chunk = chunk_scene.instantiate()
			chunk.set_chunk_position(c)
			chunk.calc(ch[1])
			add_child.call_deferred(chunk)
			all_chunks[c] = chunk
	_setInfoText.call_deferred("")
	
	while(true):
		await get_tree().create_timer(.25).timeout
		
		if savePlease > 0:
			var file = FileAccess.open("user://builtLevels/" + saveName.text, FileAccess.WRITE)
			if file == null: 
				savePlease -= 1
				printerr("failed cause ", FileAccess.get_open_error())
				continue
			var saveString = ""
			
			for chk in all_chunks:
				var chunk = all_chunks[chk]
				var pos = chk
				print("starting chunk ", chk)
				saveString += "{},{},{}:".format([pos.x,pos.y,pos.z], "{}")
				
				var prevBlk = -1
				var blkRun = 0
				for blk in chunk.blocks:
					if blk != prevBlk:
						if blkRun > 4:
							saveString += "+" + str(blkRun)
						else:
							if prevBlk != -1: 
								for i in range(blkRun):
									saveString += blkToText[prevBlk]
						saveString += blkToText[blk]
						prevBlk = blk
						blkRun = 0
					else: 
						blkRun+= 1
				saveString += "\n"
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
		
		for c in all_chunks: c.update()

func _on_save_button_pressed():
	print("a")
	savePlease += 1
