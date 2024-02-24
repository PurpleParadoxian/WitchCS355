extends Node

var mainMenuScene = preload("res://Menu.tscn")
@onready var label = $Label

var activeScene = null

func _ready():
	var mmScene = mainMenuScene.instantiate()
	activeScene = mmScene
	mmScene.hello()
	add_child(mmScene)
	label.visible = false

func changeScene(scene, info):
	label.visible = true
	remove_child(activeScene)
	var newScene = load(scene).instantiate()
	newScene.getInfo(info)
	add_child(newScene)
	activeScene = newScene
	label.visible = false
