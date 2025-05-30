extends Node2D

# Preload the world_item scene for spawning
const WORLD_ITEM_SCENE = preload("res://scenes/world_item.tscn")

# Item data
var id: String = "default_item"
var texture_path: String = "res://entities/icon_candle.png"

# Dragging state
var is_dragging: bool = false
var dragged_instance: Node = null

# Reference to the sprite
@onready var sprite: Sprite2D = $Sprite2D  # Adjust if using TextureRect

func _ready():
	print("world_item.gd _ready() called. Node children:", get_children())
	if not sprite:
		print("Error: Sprite2D node not found at $Sprite2D")
	var loaded_texture = load(texture_path)
	if loaded_texture:
		if sprite:
			sprite.texture = loaded_texture
			sprite.z_index = 1  # Ensure visibility over background
			print("WorldItem", id, "loaded with texture:", texture_path)
		else:
			print("Cannot set texture: sprite is null")
	else:
		print("Failed to load texture for WorldItem", id, "at path:", texture_path)

func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_dragging:
			print("Starting drag for WorldItem:", id)
			dragged_instance = Sprite2D.new()
			dragged_instance.texture = sprite.texture
			dragged_instance.global_position = get_global_mouse_position()
			get_tree().root.add_child(dragged_instance)
			is_dragging = true

func _process(delta: float) -> void:
	if is_dragging and dragged_instance:
		dragged_instance.global_position = get_global_mouse_position()
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			print("Mouse released for WorldItem:", id)
			var inventory = get_node_or_null("/root/main/inventory")
			var drop_in_world = true
			if inventory:
				inventory.handle_world_item_drop(self, id, texture_path)
				drop_in_world = false
			if drop_in_world:
				print("Item dropped outside inventory, spawning back in world")
				var world = get_node_or_null("/root/main/world")
				if world:
					var new_world_item = WORLD_ITEM_SCENE.instantiate()
					new_world_item.id = id
					new_world_item.texture_path = texture_path
					new_world_item.position = dragged_instance.global_position
					world.add_child(new_world_item)
			dragged_instance.queue_free()
			dragged_instance = null
			is_dragging = false
			queue_free()
