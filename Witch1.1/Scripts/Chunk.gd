@tool
extends StaticBody3D

var blocks = []
var seedAir = [Vector3(0, 0, 0)]
var faceList = []
var entities = []

var st = SurfaceTool.new()
var mesh = null
var mesh_instance = null

var material = preload("res://assets/new_standard_material_3d.tres")

var chunk_position = Vector3i() : set = set_chunk_position

func _ready():
	generate()
	build()
	update()

func generate():
	print("start generate")
	blocks = []
	blocks.resize(Global.DIMENSION.x)
	for x in Global.DIMENSION.x:
		blocks[x] = []
		blocks[x].resize(Global.DIMENSION.y)
		for y in Global.DIMENSION.y:
			blocks[x][y] = []
			blocks[x][y].resize(Global.DIMENSION.z)
			for z in Global.DIMENSION.z:
				var block = Global.AIR
				if 16<=x and x<=48 and 16<=z and z<=48:
					if 16 < y:
						if y < 40:
							block = Global.STONE
						elif y < 48:
							block = Global.DIRT
						elif y == 48:
							block = Global.GRASS
				if block != Global.AIR:
					if (x-32)*(x-32) + (y-32)*(y-32) + (z-32)*(z-32) > 16*16: block = Global.AIR
				blocks[x][y][z] = block

func depthFill(prevList, thisList):
	var newList = []
	var allList = prevList + thisList
	for item in thisList:
		
		if check_transparent(item):
			for i in Global.FACE_SIDES:
				var a = item + i
				var yes = false
				for j in range(3):
					if a[j] < 0 or Global.DIMENSION[0] <= a[j]: 
						yes = true # this should ask other chunks
						break
				if yes: continue
				if !allList.has(a) and !newList.has(a):
					newList += [a]
		else:
			var chk_blk = Global.types[blocks[item.x][item.y][item.z]]
			for i in range(6):
				var chk_item = item + Global.FACE_SIDES[i]
				if check_transparent(chk_item): # or are the same type
					faceList += [[Global.faces[i], item, chk_blk[i]]]
	return newList

func build():
	"""
	print("start build")
	for mySeed in seedAir:
		print("a")
		var prevList = []
		var thisList = [mySeed]
		while !thisList.is_empty():
			print("b")
			var newList = depthFill(prevList, thisList)
			prevList = thisList
			thisList = newList
			#await get_tree().create_timer(1).timeout
		print("number of faces: ", len(faceList))
	"""
	# I don't like that this is faster...
	for x in Global.DIMENSION.x:
		for y in Global.DIMENSION.y:
			for z in Global.DIMENSION.z:
				var item = Vector3(x, y, z)
				if !check_transparent(item):
					var chk_blk = Global.types[blocks[item.x][item.y][item.z]]
					for i in range(6):
						var chk_item = item + Global.FACE_SIDES[i]
						if check_transparent(chk_item): # or are the same type
							faceList += [[Global.faces[i], item, chk_blk[i]]]

func update():
	if mesh_instance != null:
		mesh_instance.call_deferred("queue_free")
		mesh_instance = null
	
	mesh = ArrayMesh.new()
	mesh_instance = MeshInstance3D.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	for face in faceList:
		create_face(face[0], face[1], face[2])
	
	st.generate_normals(false)
	st.set_material(material)
	st.commit(mesh)
	
	# do transparent water faces here?
	
	mesh_instance.set_mesh(mesh)
	
	add_child.call_deferred(mesh_instance)
	#mesh_instance.owner = self
	mesh_instance.create_trimesh_collision()
	
	self.visible = true
	print("success", chunk_position)

func check_transparent(off):
	for i in range(3):
		if off[i] < 0 or off[i] >= Global.DIMENSION[i]:
			return false
	return not Global.types[blocks[off.x][off.y][off.z]][Global.SOLID]

func create_face(face, off, texture_offset):
	var newOff = Global.BLOCK_SCALE * off
	var a = Global.BLOCK_SCALE*Global.vertices[face[0]] + newOff
	var b = Global.BLOCK_SCALE*Global.vertices[face[1]] + newOff
	var c = Global.BLOCK_SCALE*Global.vertices[face[2]] + newOff
	var d = Global.BLOCK_SCALE*Global.vertices[face[3]] + newOff
	
	var uv_offset = texture_offset/Global.TEXTURE_ATLAS_SIZE
	var height = 1.0 / Global.TEXTURE_ATLAS_SIZE.y
	var width = 1.0 / Global.TEXTURE_ATLAS_SIZE.x
	
	var uv_a = uv_offset + Vector2(0, 0)
	var uv_b = uv_offset + Vector2(0, height)
	var uv_c = uv_offset + Vector2(width, height)
	var uv_d = uv_offset + Vector2(width, 0)
	
	st.add_triangle_fan(([a, b, c]), ([uv_a, uv_b, uv_c]))
	st.add_triangle_fan(([a, c, d]), ([uv_a, uv_c, uv_d]))

func set_chunk_position(pos):
	chunk_position = pos
	self.position = pos*Global.DIMENSION*Global.BLOCK_SCALE
	
	#self.visible = false
