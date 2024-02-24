extends StaticBody3D

var blocks = []
var faceList = []
var entities = []

var st = SurfaceTool.new()
var mesh = null
var mesh_instance = null

var material = preload("res://assets/new_standard_material_3d.tres")

var chunk_position = Vector3i() : set = set_chunk_position

func toBlock(x, y, z):
	return (int(x)<<6) & (int(y)<<3) & (int(z))

func calc(a = null):
	if a == null: 
		generate()
	else: 
		generate(a)
		build()
	update()

func generate( bytes : PackedByteArray = PackedByteArray()):
	print("start generate")
	blocks = []
	var size = Global.DIMENSION.x*Global.DIMENSION.y*Global.DIMENSION.z
	blocks.resize(size)
	blocks.fill(Global.AIR)
	
	var i = 0
	var j = 0
	var continuing = false
	var previousBlock = 0
	while i < size and bytes.size() > j:
		var cha = bytes[j]
		j += 1
		
		if continuing:
			continuing = false
			if previousBlock != Global.AIR:
				for k in range(cha): blocks[k] = previousBlock
			i += cha
			continue
		
		match cha:
			1: blocks[i] = Global.STONE
			2: blocks[i] = Global.DIRT
			3: blocks[i] = Global.GRASS
			255: 
				continuing = true
				continue
		
		i += 1
	
	while i < size:
		# fill the rest of the blocks i to size with air
		blocks[i] = Global.AIR
		i = i+1

func build():
	for x in Global.DIMENSION.x:
		for y in Global.DIMENSION.y:
			for z in Global.DIMENSION.z:
				var item = Vector3i(x, y, z)
				if !check_transparent(item):
					var chk_blk = Global.types[blocks[toBlock(item.x, item.y, item.z)]]
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
	return not Global.types[blocks[toBlock(off.x, off.y, off.z)]][Global.SOLID]

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
	self.position = Vector3(pos*Global.DIMENSION*Global.BLOCK_SCALE)
	
	#self.visible = false

func place_block(pos, type):
	pass # handle placing blocks (modify the faces list)
