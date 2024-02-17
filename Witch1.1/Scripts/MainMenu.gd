extends Node2D

@onready var list = $ItemList
@onready var buttonDev = $Button1
@onready var buttonNormal = $Button2

var devScene = preload("res://DevWorld.tscn")

var dir : DirAccess
var item

# Called when the node enters the scene tree for the first time.
func _ready():
	dir = DirAccess.open("user://builtLevels")
	var strs = dir.get_files()
	
	for str in strs:
		list.add_item(str)

func hello():
	print("hello")

func _on_button_1_pressed():
	buttonDev.disabled = true
	buttonNormal.disabled = true
	get_parent().changeScene("res//DevWorld.tscn", list.get_item_text(item))

func _on_button_2_pressed():
	pass # I haven't implemented the normal mode yet

func _on_item_list_item_selected(index):
	item = index
	buttonDev.disabled = false
