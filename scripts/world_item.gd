extends Node2D

# Preload the world_item scene for spawning
const WORLD_ITEM_SCENE = preload("res://scenes/world_item.tscn")

# Item data
var id: String = "default_item"
var texture_path: String = "res://entities/icon_default.png"

# Dragging state
var is_dragging: bool = false
var dragged_instance: Node = null
var original_position: Vector2 = Vector2.ZERO  # Store the starting position

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
			sprite.z_index = 2
			# Set base size to 40x40 pixels, adjusting scale if texture is smaller
			var texture_size = loaded_texture.get_size()
			var scale_factor = 40.0 / max(texture_size.x, texture_size.y)
			sprite.scale = Vector2(scale_factor, scale_factor)
			print("WorldItem", id, "loaded with texture:", texture_path, "Scaled to:", sprite.scale)
		else:
			print("Cannot set texture: sprite is null")
	else:
		print("Failed to load texture for WorldItem", id, "at path:", texture_path)
	var area = $Area2D
	if area:
		print("Area2D monitoring:", area.monitoring, "input_pickable:", area.input_pickable)
		# Update CollisionShape2D to match scaled sprite
		var collision_shape = area.get_node("CollisionShape2D")
		if collision_shape and collision_shape.shape is RectangleShape2D:
			collision_shape.shape.extents = Vector2(20, 20)  # 40x40 / 2
		area.input_event.connect(_on_area_input_event)
	else:
		print("Error: Area2D not found")

func _on_area_input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	print("WorldItem", id, "received input event:", event.as_text())
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and not is_dragging:
			print("Starting drag for WorldItem:", id)
			if not sprite or not sprite.texture:
				print("Error: Cannot drag - sprite or texture is null")
				return
			original_position = self.global_position  # Use global_position to account for parent transforms
			print("Stored original position (global):", original_position)
			dragged_instance = Sprite2D.new()
			dragged_instance.texture = sprite.texture
			dragged_instance.scale = sprite.scale  # Apply same scale
			dragged_instance.z_index = 3
			dragged_instance.global_position = get_global_mouse_position()
			get_tree().root.add_child(dragged_instance)
			is_dragging = true

func _process(delta: float) -> void:
	if is_dragging and dragged_instance:
		dragged_instance.global_position = get_global_mouse_position()
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			print("Mouse released for WorldItem:", id, "Current position:", self.global_position)
			# Try to drop into inventory
			var inventory = get_tree().root.get_node_or_null("Main/inventory")
			if not inventory:
				print("Warning: Inventory node not found at /root/Main/inventory")
			var drop_succeeded = false
			if inventory:
				print("Found inventory node at /root/Main/inventory")
				drop_succeeded = inventory.handle_world_item_drop(self, id, texture_path)
			if not drop_succeeded:
				print("Item not dropped in inventory, returning to original position:", original_position)
				# Return the original item to its starting global position
				self.global_position = original_position
				print("Returned to position:", self.global_position)
			else:
				print("Item dropped in inventory, removing world item")
				# Only free the original item if the drop succeeded
				queue_free()
			# Clean up the dragged instance
			dragged_instance.queue_free()
			dragged_instance = null
			is_dragging = false
