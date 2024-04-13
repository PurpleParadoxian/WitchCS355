extends Node3D


enum {
	UP,
	DOWN,
	LEFT,
	FRONT,
	RIGHT,
	BACK
}
#enum {UP,RIGHT,BACK,DOWN,LEFT,FRONT} # better enum structure? trying to work with transitions between directions 
const rotations = [[FRONT], [FRONT, BACK, LEFT, RIGHT], [UP, DOWN, LEFT, FRONT, RIGHT, BACK]]

# Room JSON format
class MyRoom:
	var id
	var score # determines how likely a room is to be used, (hallway=10, treasure room=1, dependant=0)
	var dir # what direction the room points in (0: y, 1:-y, 2:-x, 3:x, 4:-z, 5:z)
	var rotatable # whether the shape can be rotated along the y-axis (ex: a hallway)
	var adjRooms # a list of [Vector3, int] pairs which represent the possible doors 

var allRooms = []
var builtRooms = []

func toChunkV(v:Vector3i):
	if v.x<0 or v.x>=64 or v.y<0 or v.y>=64 or v.z<0 or v.z>=64: return -1
	return (int(v.x)*64*64) + (int(v.y)*64) + (int(v.z))

# blackbox test ?? (Its the same as the vector one)
func toChunk(x, y, z):
	if x<0 or x>=64 or y<0 or y>=64 or z<0 or z>=64: return -1
	return (int(x)*64*64) + (int(y)*64) + (int(z))

func buildPossibleRooms():
	var json_as_text = FileAccess.get_file_as_string("res://preBuiltLevels/dungeon-rooms.json")
	var json_as_dict = JSON.parse_string(json_as_text)
	
	for a in json_as_dict:
		var newRoom = MyRoom.new()
		newRoom.id = a["id"]
		newRoom.score = a["score"]
		newRoom.dir = a["dir"]
		newRoom.shape = a["shape"]
		newRoom.rotatable = a["rotatable"]
		
		for i in a["roomsNeeded"]:
			newRoom.roomsNeeded += [[Vector3(i[0], i[1], i[2]), i[3], i[4]]]
		newRoom.roomPath = []
		
		allRooms[newRoom.id] = newRoom

func _ready():
	builtRooms = PackedByteArray()
	builtRooms.resize(Global.SixForCubd)
	
	# allRooms are loaded from a json file containing all rooms TODO: BUILD MORE ROOMS
	buildPossibleRooms()
	
	var firstRoom = allRooms[0]
	addRoom(Vector3(0, 0, 0), FRONT, firstRoom)
	# TODO: make canon path and sub-canon path, depth first paths of rooms to specific end points
	
	var count = 0
	# this will recursiely add the other rooms in a breadth-first fashion
	while count < Global.SixForCubd:
		count += 1
		
		testNextRoom(room[0], room[1], room[2])

# from and to are enums for the direction, a is an array of 6 numbers that represent a box
func changeRotation(to, a):
	if to == FRONT: return a
	if to == LEFT:  return [a[0], a[1], a[3], a[4], a[5], a[2]]
	if to == RIGHT: return [a[0], a[1], a[4], a[5], a[2], a[3]]
	if to == BACK:  return [a[0], a[1], a[5], a[2], a[3], a[4]]
	if to == UP:    return [a[4], a[4], a[2], a[3], a[0], a[5]]
	if to == DOWN:  return [a[4], a[5], a[2], a[3], a[0], a[1]]

func addRoom(pos: Vector3, dir: int, room: MyRoom):
	for i in room.roomsNeeded: roomsToDo.push_front([i[0]+pos, i[1], i[2]])
	for i in changeRotation(dir, room.shape):
		collisions += [[pos[0]+i[0], pos[0]+i[1], pos[1]+i[2], pos[1]+i[3], pos[2]-i[4], pos[2]-i[5]]]

# loop through all values of collisions and return true if any overlap with the room given
func testRoom(pos: Vector3, dir: int, room: MyRoom):
	var a = changeRotation(dir, room.shape)
	for i in collisions:
		for j in [0, 2, 4]:
			var b = j/2
			if pos[b]+a[j] <= i[1+j] and pos[b]+a[1+j] >= i[1+j] or \
			   pos[b]+a[j] <= i[j] and pos[b]+a[1+j] >= i[j] : return false
	return true

func doNextRoom(pos: Vector3i):
	var total = 0
	var rooms = []
	
	for room : MyRoom in allRooms:
		if room.score == 0: continue # skip dependant rooms
		# if the room won't work in this direction then skip it
		
		if dir <= DOWN and room.rotatable < 2: continue
		if testRoom(pos, dir, room):
			total += room.score
			rooms += [room]
	
	if not rooms.is_empty():
		var rn = RandomNumberGenerator.new().randi_range(0, total)
		
		for i : MyRoom in rooms:
			rn -= i.score
			if rn <= 0: 
				addRoom(pos, dir, i)
				break
