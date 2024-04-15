extends Node3D


enum { UP, DOWN, LEFT, FRONT, RIGHT, BACK }
#enum {UP,RIGHT,BACK,DOWN,LEFT,FRONT} # better enum structure? trying to work with transitions between directions 
const rotations = [[FRONT], [FRONT, BACK, LEFT, RIGHT], [UP, DOWN, LEFT, FRONT, RIGHT, BACK]]

# Room JSON format
class MyRoom:
	var id
	var score # determines how likely a room is to be used, (hallway=10, treasure room=1, dependant=0)
	var pos
	var dir # what direction the room points in (0: y, 1:-y, 2:-x, 3:x, 4:-z, 5:z)
	var rotatable # whether the shape can be rotated along the y-axis (ex: a hallway)
	var sides
	var adjRooms = [] # a list of [Vector3, int] pairs which represent the possible doors 

class AdjRoom:
	func _init(a):
		id = a[0]
		pos = a[1]
		dir = a[2]
	var id
	var pos
	var dir

var bound = 10
var boundsqr = bound*bound
var boundcub = boundsqr*bound
var allRooms = []
var specialRooms = {}
var builtRooms = null
#var builtRotat = null # doesn't work yet

func toChunkV(v:Vector3i):
	if v.x<0 or v.x>=bound or v.y<0 or v.y>=bound or v.z<0 or v.z>=bound: return -1
	return (int(v.x)*bound*bound) + (int(v.y)*bound) + (int(v.z))

# blackbox test ?? (Its the same as the vector one)
func toChunk(x, y, z):
	if x<0 or x>=bound or y<0 or y>=bound or z<0 or z>=bound: return -1
	return (int(x)*bound*bound) + (int(y)*bound) + (int(z))


func toVChunk(a):
	if a < 0 or a >= boundcub: return null
	var z = a % bound
	var y = int(a/bound) % bound
	var x = int(a/boundsqr) % bound
	return Vector3i(x, y, z)

func buildPossibleRooms():
	var json_as_text = FileAccess.get_file_as_string("res://preBuiltLevels/dungeon-rooms.json")
	var json_as_dict = JSON.parse_string(json_as_text)
	allRooms.resize(json_as_dict["nRooms"])
	
	for a in json_as_dict["rooms"]:
		var newRoom = MyRoom.new()
		newRoom.id = a["id"]
		newRoom.score = a["score"]
		newRoom.dir = a["dir"]
		newRoom.rotatable = a["rotatable"]
		newRoom.sides = a["sides"]
		
		if newRoom.score == 0:
			var special = a["special"]
			if special == "starting": 
				var b = a["pos"]
				newRoom.pos = Vector3i(b[0], b[1], b[2])
			if not specialRooms.has(special): specialRooms[special] = [newRoom]
			else: specialRooms[special] += [newRoom]
		else:
			for i in a["adjRooms"]: newRoom.adjRooms += [AdjRoom.new(i)]
		allRooms[newRoom.id] = newRoom

func _ready():
	builtRooms = PackedByteArray()
	builtRooms.resize(boundcub)
	builtRooms.fill(255)
	#builtRotat = PackedByteArray()
	#builtRotat.resize(Global.SixForCubd)
	#builtRotat.fill(4)
	
	var rng = RandomNumberGenerator.new()
	
	# allRooms are loaded from a json file containing all rooms TODO: BUILD MORE ROOMS
	buildPossibleRooms()
	
	for startingRoom in specialRooms["starting"]: addRoom(startingRoom.pos, startingRoom.dir, startingRoom)
	
	
	var count = 0
	# this will recursiely add the other rooms in a grid fashion
	while count < boundcub:
		if count%boundcub ==0: print(int(count/boundsqr),"/", bound)
		
		if builtRooms[count] != 255: # if we already have a room there, skip
			count += 1
			continue
		
		var total = 0
		var possibleRooms = []
		var fronCubSide = null
		var downCubSide = null
		var leftCubSide = null
		if count >= boundsqr: 
			var tryRoom = builtRooms[count - boundsqr]
			if tryRoom == 255: fronCubSide = 0
			else: fronCubSide = allRooms[tryRoom].sides[BACK]
		if count%boundsqr>=bound: 
			var tryRoom = builtRooms[count - bound]
			if tryRoom == 255: downCubSide = 0
			else: downCubSide = allRooms[tryRoom].sides[UP]
		if count % bound != 0: 
			var tryRoom = builtRooms[count - 1]
			if tryRoom == 255: leftCubSide = 0
			else: leftCubSide = allRooms[tryRoom].sides[RIGHT]
		
		for room : MyRoom in allRooms:
			if room.score == 0: continue # skip special rooms
			
			# if the room won't work in this rotation then skip it
			#for i in rotations[room.rotatable]:
				#if fronCubSide != null and room.sides[FRONT] != fronCubSide or \
				#   downCubSide != null and room.sides[DOWN]  != downCubSide or \
				#   leftCubSide != null and room.sides[LEFT]  != leftCubSide: continue
				
				# we keep the first permutation that fits for any room
				#total += room.score
				#possibleRooms += [[room, i]]
			if fronCubSide != null and room.sides[FRONT] != fronCubSide or \
				   downCubSide != null and room.sides[DOWN]  != downCubSide or \
				   leftCubSide != null and room.sides[LEFT]  != leftCubSide: continue
			total += room.score
			possibleRooms += [room]
		
		if not possibleRooms.is_empty():
			var rn = rng.randi_range(0, total)
			
			for i in possibleRooms:
				rn -= i.score
				if rn <= 0: 
					addRoom(toVChunk(count), FRONT, i)
					break
		
		count += 1
	print("built rooms: ", builtRooms)

# from and to are enums for the direction, a is an array of 6 numbers that represent a box
func changeRotation(to, a):
	# normal = UP, DOWN, LEFT, FRONT, RIGHT, BACK
	if to == FRONT: return a
	if to == LEFT:  return [a[UP], a[DOWN], a[FRONT], a[RIGHT], a[BACK], a[LEFT]]
	if to == RIGHT: return [a[UP], a[DOWN], a[RIGHT], a[BACK], a[LEFT], a[FRONT]]
	if to == BACK:  return [a[UP], a[DOWN], a[BACK], a[LEFT], a[FRONT], a[RIGHT]]
	if to == UP:    return [a[FRONT], a[BACK], a[LEFT], a[DOWN], a[RIGHT], a[UP]]
	if to == DOWN:  return [a[BACK], a[FRONT], a[LEFT], a[UP], a[RIGHT], a[DOWN]]

func rotDirV(from, to, a): # this doesn't work yet, I'll work on it
	pass

func addRoom(pos: Vector3i, dir: int, room: MyRoom):
	var a = toChunkV(pos)
	#builtRotat[a] = dir
	builtRooms[a] = room.id
	for i in room.adjRooms:
		addRoom(pos+room.dir, i.dir, allRooms[i.id]) # currently we cannot rotate rooms that have adjRooms (dependencies)
		#addRoom(pos+rotDirV(room.dir, dir, i.pos), i.dir, allRooms[i.id])
