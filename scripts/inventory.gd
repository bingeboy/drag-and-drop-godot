# @Description: 
# Manages the inventory, populates slots, and handles drag-and-drop.
extends Control

#preload inventory slot scene
const SLOT_SCENE = preload("res://scenes/inventory_slot.tscn")

# inventory DATA obj TODO - this could be read from json in a DB or something else that is not defined in the code
var inventory_data := [
	{
		"id": "sword",
		"texture": "res://entities/icon_skull.png"
	},
	null, #empty
	null, #empty
	{
		"id": "apple",
		"texture": "res://entities/icon_candle.png"
	}
]

# mouse pointer images
@export var mouse_hand: Texture2D = load("res://entities/hover_cursor.png")
@export var mouse_drag_hand: Texture2D = load("res://entities/drag_cursor.png")

# drag and drop
var dragged_item = null
var dragged_from_slot = null
var dragged_item_data = null
var is_dragging = false
var target_slot = null  # Track the slot under the mouse
var was_mouse_pressed = false  # Track previous mouse state

# signals
signal item_dropped(item_id, from_slot, to_slot)

# ready 
func _ready():
	var grid = $InventoryGrid
	
	for child in grid.get_children():
		child.queue_free()
	
	for i in inventory_data.size():
		var slot = SLOT_SCENE.instantiate()
		slot.slot_index = i
		if inventory_data[i] != null:
			var loaded_texture = load(inventory_data[i]["texture"])
			print("Slot", i, "loading texture:", loaded_texture)
			slot.set_item(inventory_data[i]["id"], loaded_texture)
			print("Slot", i, "after set_item. Item:", slot.item, "Visible:", slot.item.visible if slot.item else "No item")
		grid.add_child(slot)
		
		print("Slot", i, "added to grid. Position:", slot.position, "Size:", slot.size)
		
		var connection_result = slot.connect("item_pressed", Callable(self, "_on_item_pressed"))
		print("Slot", i, "signal connection result:", "Success" if connection_result == OK else "Failed with error code: " + str(connection_result))
	
	print("Inventory Loaded: ", inventory_data.size(), " slots. Initial data:", inventory_data)

# handler
func _on_item_pressed(slot):
	print("Slot", slot.slot_index, "pressed. Item present:", slot.item != null, "Dragging state:", is_dragging, "Inventory data:", inventory_data)
	var is_mouse_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if not is_dragging and slot.item and is_mouse_pressed:
		print("Starting drag from slot", slot.slot_index)
		dragged_item = slot.item
		dragged_from_slot = slot
		dragged_item_data = inventory_data[slot.slot_index]
		dragged_item.get_parent().remove_child(dragged_item)
		call_deferred("add_child", dragged_item)
		dragged_item.global_position = get_global_mouse_position() - dragged_item.size / 2
		is_dragging = true
		print("Drag initiated. Dragged item position:", dragged_item.global_position, "Parent:", dragged_item.get_parent(), "In tree:", dragged_item.is_inside_tree())

# process
func _process(delta: float) -> void:
	# Custom pointer
	if dragged_item:
		Input.set_custom_mouse_cursor(mouse_drag_hand)
	else:
		Input.set_custom_mouse_cursor(mouse_hand)
	# DRAGGING inventroy item
	if dragged_item:
		dragged_item.global_position = get_global_mouse_position() - dragged_item.size / 2
		print("Dragging. Item position:", dragged_item.global_position, "In tree:", dragged_item.is_inside_tree())
		
		# Find the slot under the mouse
		target_slot = null
		for slot in $InventoryGrid.get_children():
			var slot_rect = Rect2(slot.global_position, slot.size)
			if slot_rect.has_point(get_global_mouse_position()):
				target_slot = slot
				print("Mouse over slot", slot.slot_index)
				break
		
		# Detect mouse release
		var is_mouse_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if is_dragging and was_mouse_pressed and not is_mouse_pressed:
			print("Mouse released. Target slot:", target_slot.slot_index if target_slot else "none", "From slot:", dragged_from_slot.slot_index if dragged_from_slot else "none")
			if target_slot and target_slot != dragged_from_slot:
				var from_index = dragged_from_slot.slot_index
				var to_index = target_slot.slot_index
				if target_slot.item:  # Swap
					print("Swapping items between slot", from_index, "and slot", to_index)
					var temp_item = target_slot.item
					var temp_data = inventory_data[to_index]
					target_slot.set_item(dragged_item_data["id"], load(dragged_item_data["texture"]))
					dragged_from_slot.set_item(temp_data["id"], load(temp_data["texture"]))
					inventory_data[to_index] = dragged_item_data
					inventory_data[from_index] = temp_data
					print("Swap completed. Inventory data:", inventory_data)
				else:  # Drop into empty slot
					print("Dropping item from slot", from_index, "to slot", to_index)
					target_slot.set_item(dragged_item_data["id"], load(dragged_item_data["texture"]))
					dragged_from_slot.clear_item()
					inventory_data[to_index] = dragged_item_data
					inventory_data[from_index] = null
					print("Drop completed. Inventory data:", inventory_data)
				emit_signal("item_dropped", inventory_data[to_index]["id"], from_index, to_index)
			else:
				print("Dropped outside or on same slot", dragged_from_slot.slot_index if dragged_from_slot else "none", "Returning item")
				if dragged_from_slot:
					dragged_from_slot.set_item(dragged_item_data["id"], load(dragged_item_data["texture"]))
			
			# Clean up
			if dragged_item:
				dragged_item.queue_free()
			dragged_item = null
			dragged_from_slot = null
			dragged_item_data = null
			is_dragging = false
			target_slot = null
		
		was_mouse_pressed = is_mouse_pressed
