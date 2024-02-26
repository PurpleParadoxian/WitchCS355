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
			var chunk = chunk_scene.instantiate()
			chunk.set_chunk_position(c)
			chunk.calc(ch[1])
			all_chunks[c] = chunk
	_setInfoText.call_deferred("")
	
	while(true):
		await get_tree().create_timer(1).timeout
		
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
					if blkRun > 499 or blk != prevBlk:
						if blkRun > 4:
							saveString += "+" + str(blkRun)
						else:
							if prevBlk != -1: 
								for i in range(blkRun):
									saveString += blkToText[prevBlk]
						if blk != prevBlk: saveString += blkToText[blk]
						prevBlk = blk
						blkRun = 0
					else: 
						blkRun+= 1
				saveString += "\n"
			file.store_buffer(saveString.to_ascii_buffer())
			savePlease -= 1
		
		# handle block placements
		while not player.newBlocks.is_empty():
			player.newBlocksMut.lock()
			var a = player.newBlocks.pop_front()
			player.newBlocksMut.unlock()
			
			if not all_chunks.has(a[0]): # make a new chunk if player tries to place a block where one doesn't exist
				print("made new chunk " + str(a[0]))
				_setInfoText.call_deferred("making new chunk: " + str(a[0]))
				var chkPos = a[0]
				var chunk = chunk_scene.instantiate()
				chunk.set_chunk_position(chkPos)
				chunk.calc()
				all_chunks[chkPos] = chunk
				chunks.add_child(chunk)
			var chunk = all_chunks[a[0]]
			var blkPos = a[1]
			var type = a[2]
			_setInfoText.call_deferred("placing block: " + str(blkPos) + "\nin Chunk: " + str(a[0]))
			
			chunk.place_block(blkPos, type)
			chunk.update()
			
			_setInfoText.call_deferred("")


func _on_save_button_pressed():
	print("a")
	savePlease += 1
