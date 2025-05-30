# @Description: 
# Manages the inventory, populates slots, and handles drag-and-drop.
extends Control

#preload slots
const SLOT_SCENE = preload("res://scenes/inventory_slot.tscn")

# Inventory slot configuration
var max_slots: int = 4  # Default, will be updated from config
var inventory_data: Array = []  # Will be loaded from JSON
var is_inventory_dirty: bool = false  # Track if inventory has changed

# drag and drop
var dragged_item = null
var dragged_from_slot = null
var dragged_item_data = null
var is_dragging = false
var target_slot = null  # Track the slot under the mouse
var was_mouse_pressed = false  # Track previous mouse state

# Cursor resources with type hints
@export var hover_cursor: Texture2D = null  # Restricted to Texture2D, assignable in Inspector
@export var drag_cursor: Texture2D = null  # Restricted to Texture2D, assignable in Inspector

# signals
signal item_dropped(item_id, from_slot, to_slot)

# ready 
func _ready():
	var grid = $InventoryGrid
	
	# Load player config to get max_slots
	var config_file = FileAccess.open("res://data/player_config.json", FileAccess.READ)
	if config_file:
		var json_string = config_file.get_as_text()
		config_file.close()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			var config_data = json.data
			if config_data.has("bag_slots"):
				max_slots = config_data["bag_slots"]
				print("Loaded max_slots from player_config.json:", max_slots)
			else:
				print("No 'bag_slots' found in player_config.json, using default:", max_slots)
		else:
			print("Failed to parse player_config.json:", json.get_error_message())
	else:
		print("Failed to open player_config.json")
	
	# Load inventory data from JSON
	var inventory_file = FileAccess.open("res://data/inventory.json", FileAccess.READ)
	if inventory_file:
		var json_string = inventory_file.get_as_text()
		inventory_file.close()
		var json = JSON.new()
		var error = json.parse(json_string)
		if error == OK:
			inventory_data = json.data
			print("Loaded inventory data from JSON:", inventory_data)
		else:
			print("Failed to parse inventory.json:", json.get_error_message())
			inventory_data = []  # Fallback to empty array
	else:
		print("Failed to open inventory.json")
		inventory_data = []  # Fallback to empty array
	
	# Adjust inventory_data to match max_slots
	while inventory_data.size() < max_slots:
		inventory_data.append(null)
	if inventory_data.size() > max_slots:
		inventory_data.resize(max_slots)
	
	# Clear existing grid children
	for child in grid.get_children():
		child.queue_free()
	
	# Create slots
	for i in max_slots:
		var slot = SLOT_SCENE.instantiate()
		slot.slot_index = i
		if i < inventory_data.size() and inventory_data[i] != null:
			var loaded_texture = load(inventory_data[i]["texture"])
			print("Slot", i, "loading texture:", loaded_texture)
			slot.set_item(inventory_data[i]["id"], loaded_texture)
			print("Slot", i, "after set_item. Item:", slot.item, "Visible:", slot.item.visible if slot.item else "No item")
		grid.add_child(slot)
		
		print("Slot", i, "added to grid. Position:", slot.position, "Size:", slot.size)
		
		var connection_result = slot.connect("item_pressed", Callable(self, "_on_item_pressed"))
		print("Slot", i, "signal connection result:", "Success" if connection_result == OK else "Failed with error code: " + str(connection_result))
	
	print("Inventory Loaded: ", max_slots, " slots. Initial data:", inventory_data)
	
	# Set DeleteZone properties
	$DeleteZone.position = Vector2(100, 200)
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(1, 0, 0, 0.5)
	$DeleteZone.add_theme_stylebox_override("panel", style_box)

# Save inventory to JSON
func save_inventory() -> void:
	if not is_inventory_dirty:
		print("Inventory unchanged, skipping save")
		return
	var file = FileAccess.open("res://data/inventory.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(inventory_data, "  "))
		file.close()
		print("Saved inventory to inventory.json")
		is_inventory_dirty = false
	else:
		print("Failed to save inventory.json")

# Method to handle world item drops
func handle_world_item_drop(world_item: Node, item_id: String, texture_path: String) -> void:
	print("Handling world item drop. Item ID:", item_id, "Texture:", texture_path)
	var target_slot = null
	for slot in $InventoryGrid.get_children():
		var slot_rect = Rect2(slot.global_position, slot.size)
		if slot_rect.has_point(get_global_mouse_position()):
			target_slot = slot
			break
	
	if target_slot:
		var to_index = target_slot.slot_index
		if to_index >= max_slots:
			print("Error: Target slot", to_index, "is beyond max_slots", max_slots)
			return
		print("World item dropped into slot", to_index)
		if target_slot.item:
			print("Replacing item in slot", to_index)
		inventory_data[to_index] = { "id": item_id, "texture": texture_path }
		target_slot.set_item(item_id, load(texture_path))
		emit_signal("item_dropped", item_id, -2, to_index)
		is_inventory_dirty = true  # Mark as dirty after change

# Method to update the number of slots during gameplay
func set_max_slots(new_max_slots: int) -> void:
	if new_max_slots < 1:
		print("Error: max_slots must be at least 1")
		return
	
	var old_max_slots = max_slots
	max_slots = new_max_slots
	
	if new_max_slots > old_max_slots:
		while inventory_data.size() < new_max_slots:
			inventory_data.append(null)
	else:
		inventory_data.resize(new_max_slots)
	
	var grid = $InventoryGrid
	for child in grid.get_children():
		child.queue_free()
	
	for i in max_slots:
		var slot = SLOT_SCENE.instantiate()
		slot.slot_index = i
		if i < inventory_data.size() and inventory_data[i] != null:
			var loaded_texture = load(inventory_data[i]["texture"])
			slot.set_item(inventory_data[i]["id"], loaded_texture)
		grid.add_child(slot)
		var connection_result = slot.connect("item_pressed", Callable(self, "_on_item_pressed"))
		print("Slot", i, "signal connection result:", "Success" if connection_result == OK else "Failed with error code: " + str(connection_result))
	
	print("Inventory updated: ", max_slots, " slots. New data:", inventory_data)
	is_inventory_dirty = true  # Mark as dirty after resizing

# handler
func _on_item_pressed(slot):
	print("Slot", slot.slot_index, "pressed. Item present:", slot.item != null, "Dragging state:", is_dragging, "Inventory data:", inventory_data)
	var is_mouse_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if not is_dragging and slot.item and is_mouse_pressed:
		print("Starting drag from slot", slot.slot_index)
		if slot.slot_index >= max_slots:
			print("Error: Slot", slot.slot_index, "is beyond max_slots", max_slots, "Cannot drag")
			return
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
	# Temporary test code to save manually
	if Input.is_action_just_pressed("ui_accept"):  # Enter key
		save_inventory()
	
	if dragged_item:
		dragged_item.global_position = get_global_mouse_position() - dragged_item.size / 2
		print("Dragging. Item position:", dragged_item.global_position, "In tree:", dragged_item.is_inside_tree())
		
		target_slot = null
		for slot in $InventoryGrid.get_children():
			var slot_rect = Rect2(slot.global_position, slot.size)
			if slot_rect.has_point(get_global_mouse_position()):
				target_slot = slot
				print("Mouse over slot", slot.slot_index)
				break
		
		if is_dragging and drag_cursor:
			Input.set_custom_mouse_cursor(drag_cursor)
		elif target_slot and target_slot.item and hover_cursor:
			Input.set_custom_mouse_cursor(hover_cursor)
		else:
			Input.set_custom_mouse_cursor(null)
		
		var is_mouse_pressed = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		if is_dragging and was_mouse_pressed and not is_mouse_pressed:
			print("Mouse released. Target slot:", target_slot.slot_index if target_slot else "none", "From slot:", dragged_from_slot.slot_index if dragged_from_slot else "none")
			var delete_zone_rect = Rect2($DeleteZone.global_position, $DeleteZone.size)
			if delete_zone_rect.has_point(get_global_mouse_position()):
				print("Item dropped in DeleteZone. Deleting item from slot", dragged_from_slot.slot_index)
				var from_index = dragged_from_slot.slot_index
				inventory_data[from_index] = null
				dragged_from_slot.clear_item()
				emit_signal("item_dropped", null, from_index, -1)
				is_inventory_dirty = true
			elif target_slot and target_slot != dragged_from_slot:
				var from_index = dragged_from_slot.slot_index
				var to_index = target_slot.slot_index
				if to_index >= max_slots:
					print("Error: Target slot", to_index, "is beyond max_slots", max_slots, "Returning item")
					dragged_from_slot.set_item(dragged_item_data["id"], load(dragged_item_data["texture"]))
				else:
					if target_slot.item:
						print("Swapping items between slot", from_index, "and slot", to_index)
						var temp_item = target_slot.item
						var temp_data = inventory_data[to_index]
						target_slot.set_item(dragged_item_data["id"], load(dragged_item_data["texture"]))
						dragged_from_slot.set_item(temp_data["id"], load(temp_data["texture"]))
						inventory_data[to_index] = dragged_item_data
						inventory_data[from_index] = temp_data
						print("Swap completed. Inventory data:", inventory_data)
					else:
						print("Dropping item from slot", from_index, "to slot", to_index)
						target_slot.set_item(dragged_item_data["id"], load(dragged_item_data["texture"]))
						dragged_from_slot.clear_item()
						inventory_data[to_index] = dragged_item_data
						inventory_data[from_index] = null
						print("Drop completed. Inventory data:", inventory_data)
					emit_signal("item_dropped", inventory_data[to_index]["id"], from_index, to_index)
					is_inventory_dirty = true
			else:
				print("Dropped outside or on same slot", dragged_from_slot.slot_index if dragged_from_slot else "none", "Returning item")
				if dragged_from_slot:
					dragged_from_slot.set_item(dragged_item_data["id"], load(dragged_item_data["texture"]))
			
			if dragged_item:
				dragged_item.queue_free()
			dragged_item = null
			dragged_from_slot = null
			dragged_item_data = null
			is_dragging = false
			target_slot = null
			Input.set_custom_mouse_cursor(null)
		
		was_mouse_pressed = is_mouse_pressed

# Handle game exit or scene change
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_inventory()
