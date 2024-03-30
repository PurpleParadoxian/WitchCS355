extends Node3D

# Room JSON format

class MyRoom:
	var id
	var score # determines how likely a room is to be used, (hallway = 10, treasure room = 1)
	var dir # what direction the room points in (0: x, 1:y, 2:z, 3:-x, 4:-y, 5:-z)
	var box  = BoxShape3D.new() # shape of the room
	var area = Area3D.new()
	var roomsNeeded # a list of [Vector3, int] pairs which represent the possible doors 

var roomsToDo = []
var allRooms = {}
#var rotations = [Vector3(0, 0, 0), Vector3(90, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0)]

func buildPossibleRooms():
	var json_as_text = FileAccess.get_file_as_string("res://preBuiltLevels/dungeon.json")
	var json_as_dict = JSON.parse_string(json_as_text)
	
	for a in json_as_dict:
		var newRoom = MyRoom.new()
		newRoom.id = a["id"]
		newRoom.score = a["score"]
		newRoom.dir = a["dir"]
		var temp = a["shape"]
		newRoom.box.size = Vector3(temp[0], temp[1], temp[2])
		newRoom.area.add_child(newRoom.box)
		
		for i in a["roomsNeeded"]:
			newRoom.roomsNeeded += [[Vector3(i[0], i[1], i[2]), i[3]]]
		
		for i in a["roomType"]:
			if not allRooms.has(i): allRooms[i] = []
			allRooms[i] += [newRoom]
	

# Called when the node enters the scene tree for the first time.
func _ready():
	# MyRooms will be loaded from a file containing all possible rooms
	buildPossibleRooms()
	
	# 
	
	# TODO: make canon path and sub-canon path
	
	# do all other paths
	while not roomsToDo.is_empty():
		var roomTo = roomsToDo.pop_front()
		# add an end if the pos is too 
		testNextRoom

func testNextRoom(pos : Vector3, dir: int):
	var total = 0
	var rooms = []
	for testRoom : MyRoom in allRooms:
		var testArea = testRoom.area
		#testArea.add_child(testRoom.box)
		testArea.position = pos
		#testArea.rotation = rotations[dir]
		
		if testRoom.has_overlapping_areas():
			testArea.collision_layer = 0
		else:
			total += testRoom.score
			rooms += [testRoom]
		
	
	if not rooms.is_empty():
		var rn = RandomNumberGenerator.new().randi_range(0, total)
		
		for i : MyRoom in rooms:
			rn -= i.score
			if rn <= 0: 
				for j in i.roomsNeeded:
					testNextRoom(j[0] + pos, j[1])
				break
