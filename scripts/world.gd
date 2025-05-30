extends Node2D

# Preload the world_item scene
const WORLD_ITEM_SCENE = preload("res://scenes/world_item.tscn")

# Item data (for random spawning)
var item_templates = [
	{ "id": "potion", "texture": "res://entities/npc-2.png" },
	{ "id": "coin", "texture": "res://entities/icon_skull.png" },
	{ "id": "gem", "texture": "res://entities/icon_candle.png" }
]

func _ready():
	print("world.gd _ready() called, spawning items")
	# Spawn 5 random items for POC
	for i in range(5):
		print("item spawned =============================================================")
		spawn_random_item()

func spawn_random_item():
	var item_data = item_templates[randi() % item_templates.size()]
	var world_item = WORLD_ITEM_SCENE.instantiate()
	if not world_item:
		print("Failed to instantiate world_item.tscn")
		return
	world_item.id = item_data["id"]
	world_item.texture_path = item_data["texture"]
	# Adjusted for Camera2D Zoom (2, 2) in a 640x480 viewport
	var x = randi_range(160, 480)  # Visible range with Zoom (2, 2)
	var y = randi_range(120, 360)  # Visible range with Zoom (2, 2)
	world_item.position = Vector2(x, y)
	add_child(world_item)
	print("Spawned", item_data["id"], "at", world_item.position)
