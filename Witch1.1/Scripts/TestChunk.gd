@tool
extends StaticBody3D

var blocks
var faceList = {}
var entities = []

var st = SurfaceTool.new()
var mesh = null
@onready var mesh_instance : MeshInstance3D = $MeshInstance3D

const BLOCK_SCALES = [0.125, 0.125*2, 0.125*4, 0.125*8, .125*16, .125*16*5]

var material = StandardMaterial3D.new()

var chunk_scale := 0 : set = set_chunk_scale
var chunk_position := Vector3i() : set = set_chunk_position

func _ready():
	material.vertex_color_use_as_albedo = true

# blackbox test 1
func toBlockV(v:Vector3i):
	if v.x<0 or v.x>=64 or v.y<0 or v.y>=64 or v.z<0 or v.z>=64: return -1
	return (int(v.x)*64*64) + (int(v.y)*64) + (int(v.z))

# blackbox test ?? (Its the same as the vector one)
func toBlock(x, y, z):
	if x<0 or x>=64 or y<0 or y>=64 or z<0 or z>=64: return -1
	return (int(x)*64*64) + (int(y)*64) + (int(z))

func lessThanV(v, a):
	return v.x<a or v.y<a or v.z<a

func greaterThanV(v, a):
	return v.x>a or v.y>a or v.z>a

func calc():
	generate()
	build()
	update()

# blackbox test 4
func generate():
	var theString = "a+83219d+20a+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42d+20a+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794da+18da+1258da+18da+2794d+20a+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42da+18da+42d+20a"
	blocks = PackedByteArray()
	var size = Global.SixForCubd
	blocks.resize(size)
	blocks.fill(Global.AIR)
	
	var i = 0
	var j = 0
	var continuing = false
	var previousBlock = 0
	var strLen = len(theString)
	while i < size and strLen > j:
		var cha = ""
		if continuing:
			while strLen > j and theString[j].is_valid_int():
				cha += theString[j]
				j+= 1
			continuing = false
			if previousBlock != Global.AIR:
				for k in range(i, i+int(cha)): blocks[k] = previousBlock
			i += int(cha)
			continue
		else:
			cha = theString[j]
			j += 1
		
		match cha:
			"a": previousBlock = Global.AIR
			"s": 
				previousBlock = Global.STONE
				blocks[i] = Global.STONE
			"d": 
				previousBlock = Global.DIRT
				blocks[i] = Global.DIRT
			"g": 
				previousBlock = Global.GRASS
				blocks[i] = Global.GRASS
			"+": 
				continuing = true
				continue
		
		i += 1
	# the rest of the blocks are already air

# blackbox test 2
func build():
	for x in Global.DIMENSION.x:
		for y in Global.DIMENSION.y:
			for z in Global.DIMENSION.z:
				var item = Vector3i(x, y, z)
				if !check_transparent(item):
					var chk_blk = Global.types[blocks[toBlockV(item)]]
					for i in range(6):
						var chk_item = item + Global.FACE_SIDES[i]
						if check_transparent(chk_item): # or are the same type
							faceList[[i, item]] = chk_blk[Global.COLOR]

func update():
	if faceList.is_empty(): return
	
	mesh = ArrayMesh.new()
	st.set_material(material)
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for face in faceList:
		create_face(face[0], face[1], faceList[face])
	
	st.generate_normals(false)
	st.commit(mesh)
	
	# do transparent water faces here?
	mesh.surface_set_material(0, material)
	mesh_instance.set_mesh(mesh)
	
	mesh_instance.create_trimesh_collision.call_deferred()
	
	self.visible = true
	#print("update success ", chunk_position)

# blackbox test 3
func check_transparent(off):
	if greaterThanV(off, Global.DIMENSION[0]-1) or lessThanV(off, 0): return false
	return not Global.types[blocks[toBlockV(off)]][Global.SOLID]

func oppo_face(face):
	return face + (1 if posmod(face, 2)==0 else -1)

func create_face(faceNum, off, color):
	var face = Global.faces[faceNum]
	var newOff = Global.BLOCK_SCALE * off
	var a = Global.BLOCK_SCALE*Global.vertices[face[0]] + newOff
	var b = Global.BLOCK_SCALE*Global.vertices[face[1]] + newOff
	var c = Global.BLOCK_SCALE*Global.vertices[face[2]] + newOff
	var d = Global.BLOCK_SCALE*Global.vertices[face[3]] + newOff
	
	var colors = []
	colors.resize(4)
	colors.fill(color)
	#print(color)
	st.add_triangle_fan([a, b, c, d], [], colors, [], [], [])

func set_chunk_scale(scale: int):
	chunk_scale = scale
	self.position = Vector3(chunk_position*Global.DIMENSION*BLOCK_SCALES[chunk_scale])
	mesh_instance.scale = Vector3.ONE*BLOCK_SCALES[chunk_scale]/Global.BLOCK_SCALE
	#mesh_instance.force_update_transform()

func set_chunk_position(pos):
	chunk_position = pos
	self.position = Vector3(pos*Global.DIMENSION*BLOCK_SCALES[chunk_scale])
	#print(self.position)

func place_block(pos, type):
	#print("chunk ", chunk_position, " accepting ", Global.BLOCK_NAME_LIST[type], " at ", pos)
	#print(len(faceList))
	
	var curTrans = check_transparent(pos)
	var newTrans = not Global.types[type][Global.SOLID]
	var newColor = Global.types[type][Global.COLOR] if not newTrans else null
	#print(curTrans, newTrans, newColor)
	if curTrans != newTrans:
		for i in range(6):
			var chk_pos = pos + Global.FACE_SIDES[i]
			
			var chk_blk
			if greaterThanV(chk_pos, 63): chk_blk = Global.types[0]
			else: chk_blk = Global.types[blocks[toBlockV(chk_pos)]]
			
			var chkTrans = not chk_blk[Global.SOLID]
			var j = oppo_face(i)
			
			if  chkTrans == newTrans: # get rid of any faces in faceList that shouldn't be there
				faceList.erase([i, pos] if newTrans else [j, chk_pos])
			elif chkTrans != newTrans: # add any that need to be
				var c = newColor if chkTrans else chk_blk[Global.COLOR]
				var b = [j, chk_pos] if newTrans else [i, pos]
				#print("adding ", b)
				faceList[b] = c
	elif not curTrans and not newTrans:
		for i in range(6):
			var a = [i, pos]
			if faceList.has(a):
				faceList[a] = newColor
	blocks[toBlockV(pos)] = type
	#print(len(faceList))

func saveChunk():
	var blkToText = ["a", "d", "g", "s"]
	var prevBlk = -1
	var blkRun = 0
	var saveString = ""
	for blk in blocks:
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
	return saveString

func _get_property_list():
	#if Engine.is_editor_hint(): return
	# But in game, Godot will see this
	return [
		{
			"name": "blocks",
			"type": TYPE_PACKED_BYTE_ARRAY,
			"usage": PROPERTY_USAGE_STORAGE
		},
		{
			"name": "faceList",
			"type": TYPE_DICTIONARY,
			"usage": PROPERTY_USAGE_STORAGE
		}
		
	]
