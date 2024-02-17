extends Node

var mainMenuScene = preload("res://Menu.tscn")
@onready var label = $Label

var activeScene = mainMenuScene

func _ready():
	mainMenuScene.instantiate()
	mainMenuScene.hello()
	add_child(mainMenuScene)
	label.visible = false

func changeScene(scene, info):
	label.visible = true
	remove_child(activeScene)
	var newScene = load(scene).instantiate()
	newScene.getInfo(info)
	add_child(newScene)
	activeScene = newScene
	label.visible = false
