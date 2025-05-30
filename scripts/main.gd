extends Node2D

func _ready():
	var world = load("res://scenes/world.tscn").instantiate()
	add_child(world)
	world.name = "world"

	var inventory = load("res://scenes/inventory.tscn").instantiate()
	add_child(inventory)
	inventory.name = "inventory"

	var camera = Camera2D.new()
	camera.position = Vector2(320, 240)
	camera.zoom = Vector2(1, 1)
	add_child(camera)
	camera.make_current()
