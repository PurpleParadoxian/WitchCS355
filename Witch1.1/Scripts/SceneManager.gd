extends Node

var mainMenuScene = preload("res://scenes/Menu.tscn")
@onready var label = $Label

var activeScene = null

func _ready():
	var mmScene = mainMenuScene.instantiate()
	activeScene = mmScene
	mmScene.changeScene.connect(_on_change_scene)
	add_child(mmScene)
	label.visible = false

func hi(a, b):
	print(a, b)

func _on_change_scene(scenePath : String, info : Variant):
	print("recieved \"", scenePath, ", ", info, "\"")
	label.visible = true
	remove_child(activeScene)
	var newScene = load(scenePath).instantiate()
	print("changeScene ", info)
	newScene.getInfo(info)
	add_child(newScene)
	activeScene = newScene
	label.visible = false
