@tool
extends StaticBody3D

var blocks = []
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

func toBlock(x, y, z):
	return (int(x)<<6) & (int(y)<<6) & (int(z)<<6)

func generate():
	print("start generate")
	blocks = []
	blocks.resize(Global.DIMENSION.x*Global.DIMENSION.y*Global.DIMENSION.z)
	for x in Global.DIMENSION.x:
		for y in Global.DIMENSION.y:
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
				blocks[toBlock(x, y, z)] = block

func build():
	# I don't like that this is faster...
	for x in Global.DIMENSION.x:
		for y in Global.DIMENSION.y:
			for z in Global.DIMENSION.z:
				var item = Vector3(x, y, z)
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

func placeBlock():
	pass

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
