extends GutTest

class TestWorldScript:
	extends GutTest
	
	var world = load("res://Scripts/DevWorld.gd")
	var _world = null
	
	func before_each():
		_world = world.new()
	
	#Acceptance Test
	func test_str2Vec3():
		var validTests = ["1,2,3", "-1,-7,2", "0,0,0", "5, 3, -2"]
		var equals = [Vector3i(1,2,3), Vector3i(-1,-7,2), Vector3i.ZERO, Vector3i(5, 3, -2)]
		var invalidTests = ["", "1, 5, 2, 3", "hello james"]
		
		for i in range(len(validTests)):
			assert_eq(_world.strToVec3(validTests[i]), equals[i])
		for i in range(len(invalidTests)):
			assert_null(_world.strToVec3(invalidTests[i]))
		_world.free()

class TestChunkScript:
	extends GutTest
	
	var toBlock_trueThings = []
	var toBlock_falseThings = []
	var build_blockPos = [Vector3i(3, 3, 3), Vector3i(10, 3, 3), Vector3i(4, 3, 3), Vector3i(6, 6, 1)]
	var rng = RandomNumberGenerator.new()
	var chunk = load("res://Scripts/Chunk.gd")
	var _chunk = null
	
	func before_all():
		toBlock_trueThings = [Vector3i(0, 0, 0), Vector3i(25, 7, 54), Vector3i(63, 63, 63)]
		toBlock_falseThings = [Vector3i(-1, 0, 0), Vector3i(0, -1, 0), Vector3i(0, 0, -1), 
							Vector3i(64, 63, 63), Vector3i(63, 64, 63), Vector3i(63, 63, 64)]
		for i in range(10):
			toBlock_falseThings += [Vector3i(rng.randi_range(64, 1000), rng.randi_range(64, 1000), rng.randi_range(64, 1000))]
		for i in range(10):
			toBlock_falseThings += [Vector3i(rng.randi_range(-1000, -1), rng.randi_range(-1000, -1), rng.randi_range(-1000, -1))]
		for i in range(20):
			toBlock_trueThings += [Vector3i(rng.randi_range(0, 63), rng.randi_range(0, 63), rng.randi_range(0, 63))]
	
	func before_each():
		_chunk = chunk.new()
	
	#Acceptance Test
	func test_toBlockTrue():
		for thing in toBlock_trueThings:
			assert_ne(_chunk.toBlockV(thing), -1)
		_chunk.free()
	
	#Acceptance Test
	func test_toBlockFalse():
		for thing in toBlock_falseThings:
			assert_eq(_chunk.toBlockV(thing), -1)
		_chunk.free()
	
	#Acceptance Test
	func test_build():
		_chunk.generate()
		for i in build_blockPos:
			_chunk.blocks[_chunk.toBlockV(i)] = 1
		
		_chunk.build()
		assert_eq(len(_chunk.faceList), 22)
		_chunk.free()
	
	#Acceptance Test
	func test_checkTransparentTrues():
		_chunk.generate()
		for thing in toBlock_trueThings:
			assert_true(_chunk.check_transparent(thing))
		_chunk.free()
	
	#Acceptance Test
	func test_checkTransparentFalses():
		_chunk.generate()
		for thing in toBlock_falseThings:
			assert_false(_chunk.check_transparent(thing))
		_chunk.free()
	
	#Acceptance Test
	func test_checkTransparentRandoms():
		var transparent_things = []
		for i in range(20):
			transparent_things += [Vector3i(rng.randi_range(0, 63), rng.randi_range(0, 63), rng.randi_range(0, 63))]
		_chunk.generate()
		
		for i in transparent_things:
			_chunk.blocks[_chunk.toBlockV(i)] = 1
			assert_false(_chunk.check_transparent(i))
		_chunk.free()
	
	#Acceptance Test
	func test_generate1():
		var genTest = ""
		
		_chunk.generate(genTest)
		assert_does_not_have(_chunk.blocks, 1)
		assert_does_not_have(_chunk.blocks, 2)
		assert_does_not_have(_chunk.blocks, 3)
		_chunk.free()
	
	#Acceptance Test
	func test_generate2():
		var genTest = "a+250g+4"
		
		_chunk.generate(genTest)
		assert_does_not_have(_chunk.blocks, 1)
		assert_has(_chunk.blocks, 2)
		assert_does_not_have(_chunk.blocks, 3)
		_chunk.free()
	
	#Acceptance Test
	func test_generate3():
		var genTest = "ss"
		
		_chunk.generate(genTest)
		assert_does_not_have(_chunk.blocks, 1)
		assert_does_not_have(_chunk.blocks, 2)
		assert_has(_chunk.blocks, 3)
		
		assert_eq(_chunk.blocks[0], 3)
		assert_eq(_chunk.blocks[1], 3)
		assert_eq(_chunk.blocks[2], 0)
		_chunk.free()
	
	#Acceptance Test
	func test_generate4():
		var genTest = "g+5ssag"
		
		_chunk.generate(genTest)
		assert_does_not_have(_chunk.blocks, 1)
		assert_has(_chunk.blocks, 2)
		assert_has(_chunk.blocks, 3)
		
		for i in range(5): assert_eq(_chunk.blocks[i], 2)
		assert_eq(_chunk.blocks[6], 3)
		assert_eq(_chunk.blocks[7], 3)
		assert_eq(_chunk.blocks[8], 0)
		assert_eq(_chunk.blocks[9], 2)
		
		_chunk.free()
	
	#Acceptance Test
	func test_placeBlock():
		_chunk.generate()
		var equs = Global.types[1][Global.COLOR]
		var a = Vector3i(1, 1, 1)
		_chunk.place_block(a, 1)
		for i in range(6):
			assert_has(_chunk.faceList, [i, a])
			if _chunk.faceList.has([i, a]):
				assert_eq(_chunk.faceList[[i, a]], equs)
		
		a = Vector3i(2, 1, 1)
		_chunk.place_block(a, 1)
		var five = 0
		for i in range(6):
			if _chunk.faceList.has([i, a]): five+= 1
		assert_eq(five, 5)
		
		a = Vector3i(3, 1, 1)
		_chunk.place_block(a, 1)
		var b = Vector3i(2, 1, 1)
		_chunk.place_block(b, 0)
		b = Vector3i(1, 1, 1)
		for i in range(6):
			assert_has(_chunk.faceList, [i, a])
			assert_has(_chunk.faceList, [i, b])
			if _chunk.faceList.has([i, a]):
				assert_eq(_chunk.faceList[[i, a]], equs)
			if _chunk.faceList.has([i, b]):
				assert_eq(_chunk.faceList[[i, b]], equs)
		
		_chunk.free()

class Test_blockPlacing:
	extends GutTest
	
	var world = preload("res://Scripts/DevWorld.gd")
	var player = preload("res://Scripts/DevPlayer.gd")
	var _world = null
	var _player = null
	
	func before_all():
		_world = world.new()
		_player = player.new()
		
		_player.placeBlocks.connect(_world.place_new_block)
	
	#Integration Test
	func test_playerPlaceBlock():
		_player.placeBlocks.emit([Vector3i(3, 3, 3), Vector3i(3, 3, 3)], [Vector3i(32, 56, 10), Vector3i(32, 55, 10)], [3, 3])
		
		assert_eq(len(_world.newBlocks), 2)
		
		_world.free()
		_player.free()















