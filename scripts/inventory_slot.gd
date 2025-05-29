extends PanelContainer

signal item_pressed(slot)

var item = null
var slot_index: int = 0

func _ready():
	print("Slot", slot_index, "initialized. Final position:", position)
	var gui_connection = connect("gui_input", Callable(self, "_on_gui_input"))
	print("Slot", slot_index, "gui_input signal connection result:", "Success" if gui_connection == OK else "Failed with error code: " + str(gui_connection))

func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			print("Mouse pressed on slot", slot_index, "at position:", get_global_mouse_position())
		else:
			print("Mouse released on slot", slot_index, "at position:", get_global_mouse_position())
		emit_signal("item_pressed", self)
	elif event is InputEventMouseMotion:
		print("Mouse moved over slot", slot_index, "at position:", get_global_mouse_position())

func set_item(item_id: String, texture: Texture):
	if item:
		remove_child(item)
		item.queue_free()
	
	item = TextureRect.new()
	item.texture = texture
	item.visible = true
	item.mouse_filter = MOUSE_FILTER_IGNORE
	item.name = item_id
	item.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	item.size = Vector2(40, 40)
	add_child(item)
	move_child(item, get_child_count() - 1)
	item.position = Vector2.ZERO
	
	print("Slot", slot_index, "set_item called. Item:", item, "Texture:", item.texture, "Visible:", item.visible, "Position:", item.position, "In tree:", item.is_inside_tree())

func clear_item():
	if item:
		remove_child(item)
		item.queue_free()
		item = null
