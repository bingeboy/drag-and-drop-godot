extends PanelContainer

# Slot index
var slot_index: int = 0

# Item data
var item: Node = null

# Signal for item interaction
signal item_pressed(slot)

func _ready() -> void:
	connect("gui_input", Callable(self, "_on_gui_input"))

func set_item(item_id: String, texture: Texture2D) -> void:
	print("Setting item in slot", slot_index, "to ID:", item_id)
	if item:
		clear_item()
	item = TextureRect.new()
	item.texture = texture
	item.expand_mode = TextureRect.EXPAND_FIT_WIDTH
	item.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Ensure the TextureRect fits within the PanelContainer
	item.size = Vector2(40, 40)  # Explicit size to match GridContainer slots
	add_child(item)
	print("Item set in slot", slot_index, "Item node:", item)

func clear_item() -> void:
	print("Clearing item in slot", slot_index)
	if item:
		if item.get_parent() == self:
			remove_child(item)
		item.queue_free()
		item = null

func _on_gui_input(event: InputEvent) -> void:
	print("Slot", slot_index, "received input:", event.as_text())
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Slot", slot_index, "clicked")
		emit_signal("item_pressed", self)
