extends Node3D

class MyRoom:
	var area = Area3D.new()
	var score # determines how likely a room is to be used, (hallway = 10, treasure room = 1)
	var roomsNeeded # a list of [Vector3i, int] pairs which represent the possible doors 
	var shape : CollisionShape3D # shape of the room

var possibleRooms = []
var rotations = [Vector3(0, 0, 0), Vector3(90, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0), Vector3(0, 0, 0)] #TODO: Fix rotations for rooms based on dir

# Called when the node enters the scene tree for the first time.
func _ready():
	# MyRooms will be loaded from a file containing all possible rooms
	
	
	var i = possibleRooms[0].roomsNeeded
	testNextRoom(i[0], i[1])

func testNextRoom(pos : Vector3i, dir: int):
	var total = 0
	var rooms = []
	for testRoom : MyRoom in possibleRooms:
		var testArea = testRoom.area
		testArea.add_child(testRoom.shape)
		testArea.position = pos
		testArea.rotation = rotations[dir]
		
		if not testRoom.has_overlapping_areas():
			total += testRoom.score
			rooms += [testRoom]
	
	if not rooms.is_empty():
		var rn = RandomNumberGenerator.new().randi_range(0, total)
		
		for i : MyRoom in rooms:
			rn -= i.score
			if rn <= 0: 
				for j in i.roomsNeeded:
					testNextRoom(j[0], j[1])
