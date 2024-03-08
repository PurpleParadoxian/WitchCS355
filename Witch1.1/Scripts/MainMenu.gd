extends Node2D

@onready var list = $ItemList
@onready var buttonDev = $Button1
@onready var buttonNormal = $Button2

signal changeScene(scenePath : String, info : Variant)

var dir : DirAccess
var item

# Called when the node enters the scene tree for the first time.
func _ready():
	dir = DirAccess.open("user://")
	if not dir.dir_exists("builtLevels"):
		dir.make_dir("builtLevels")
	dir.change_dir("builtLevels")
	var strs = dir.get_files()
	
	for s in strs:
		list.add_item(s)

func _on_button_1_pressed():
	buttonDev.disabled = true
	buttonNormal.disabled = true
	print("emitted")
	var a = len(changeScene.get_connections())
	if a != 0:
		changeScene.emit("res://scenes/DevWorld.tscn", [list.get_item_text(item), true])

func _on_button_2_pressed():
	pass # I haven't implemented the normal mode yet

func _on_item_list_item_selected(index):
	print('selected soemthing')
	item = index
	buttonDev.disabled = false
