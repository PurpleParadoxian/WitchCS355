extends Node3D


enum {
	UP,
	DOWN,
	LEFT,
	RIGHT,
	FRONT,
	BACK
}

# Room JSON format
class MyRoom:
	var id
	var score # determines how likely a room is to be used, (hallway = 10, treasure room = 1)
	var dir # what direction the room points in (0: x, 1:y, 2:z, 3:-x, 4:-y, 5:-z)
	var shape # shape of the room
	var rotatable # whether the shape can be rotated along the y-axis (ex: a hallway)
	var roomsNeeded # a list of [Vector3, int] pairs which represent the possible doors 
	var roomPath # a list of [Vector3, MyRoom] paris which represent what room is off of this ione

var roomsToDo = []
var allRooms = {}
var collisions = []

func buildPossibleRooms():
	var json_as_text = FileAccess.get_file_as_string("res://preBuiltLevels/dungeon.json")
	var json_as_dict = JSON.parse_string(json_as_text)
	
	for a in json_as_dict:
		var newRoom = MyRoom.new()
		newRoom.id = a["id"]
		newRoom.score = a["score"]
		newRoom.dir = a["dir"]
		newRoom.shape = a["shape"]
		newRoom.rotatable = a["rotatable"]==1
		
		for i in a["roomsNeeded"]:
			newRoom.roomsNeeded += [[Vector3(i[0], i[1], i[2]), i[3], i[4]]]
		newRoom.roomPath = []
		
		for i in a["roomType"]:
			if not allRooms.has(i): allRooms[i] = []
			allRooms[i] += [newRoom]

func _ready():
	# allRooms are loaded from a file containing all possible rooms TODO: BUILD MORE ROOMS
	buildPossibleRooms()
	
	var firstRoom = allRooms["starting"][0]
	# TODO: make canon path and sub-canon path
	addRoom(Vector3(0, 0, 0), FRONT, firstRoom)
	# this will recursiely add the other rooms in a depth-first fashion
	testNextRoom(Vector3(0, 0, 0)+firstRoom.roomsNeeded[0], firstRoom.roomsNeeded[1], firstRoom.roomsNeeded[2])

# from and to are enums for the direction, a is an array of 6 numbers that represent a box
func changeRotation(from, to, a): #TODO: DOESN'T WORK
	pass

func addRoom(pos: Vector3, dir: int, room: MyRoom): # TODO: rotation doesn't work yet
	for i in changeRotation(room.dir, dir, room.shape):
		collisions += [[pos[0]+i[0], pos[0]+i[1], pos[1]+i[2], pos[1]+i[3], pos[2]+i[4], pos[2]+i[5]]]

# loop through all values of collisions and return true if any overlap with the room given
func testRoom(pos: Vector3, dir: int, room: MyRoom): # TODO: rotation doesn't work yet
	var a = changeRotation(room.dir, dir, room.shape)
	for i in collisions:
		for j in [0, 2, 4]:
			var b = j/2
			if pos[b]+a[j] <= i[1+j] and pos[b]+a[1+j] >= i[1+j] or \
			   pos[b]+a[j] <= i[j] and pos[b]+a[1+j] >= i[j] : return false
	return true

func testNextRoom(pos: Vector3, dir: int, roomType: String): # TODO: rotation doesn't work yet
	var total = 0
	var rooms = []
	
	for room : MyRoom in allRooms:
		if room.dir != dir and not room.rotatable: continue # if the room won't work in this direction then skip it
		if testRoom(pos, dir, room):
			total += room.score
			rooms += [room]
	
	if not rooms.is_empty():
		var rn = RandomNumberGenerator.new().randi_range(0, total)
		
		for i : MyRoom in rooms:
			rn -= i.score
			if rn <= 0: 
				addRoom(pos, dir, i)
				for j in i.roomsNeeded:
					testNextRoom(j[0] + pos, j[1], j[2])
				break
