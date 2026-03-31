@tool
extends Control

# ------------- [Private Variable] -------------
var _all_logs: Array[Dictionary] = []
# category (String) -> is_active (bool)
var _active_filters: Dictionary[String, bool] = {}
var _is_rebuilding: bool = false
# Time presets: name -> duration in seconds (-1.0 = show all)
var _time_presets: Dictionary[String, float] = {"All": -1.0, "30s": 30.0, "1m": 60.0, "5m": 300.0}
var _active_time_filter: float = -1.0
var _current_time_filter_button: Button = null

@onready var clear_button: Button = %ClearButton
@onready var log_display: RichTextLabel = %RichTextLabel
@onready var filter_container: HBoxContainer = %FilterContainer
@onready var time_filter_container: HBoxContainer = %TimeFilterContainer


# ------------- [Callbacks] -------------
func _ready() -> void:
	clear_button.pressed.connect(_on_clear_pressed)
	log_display.bbcode_enabled = true
	# enable automatic scrolling
	log_display.scroll_following = true
	_add_time_filter_buttons()


# ------------- [Private Method] -------------
func _add_filter_button(category: String) -> void:
	_active_filters[category] = true
	var btn := Button.new()
	btn.text = category
	btn.toggle_mode = true
	btn.button_pressed = true
	btn.toggled.connect(_on_filter_toggled.bind(category, btn))
	btn.gui_input.connect(_on_filter_gui_input.bind(category))
	_update_button_style(btn, true)
	filter_container.add_child(btn)


func _add_time_filter_buttons() -> void:
	for preset_name: String in _time_presets.keys():
		var btn := Button.new()
		btn.text = preset_name
		btn.toggle_mode = true
		if preset_name == "All":
			btn.button_pressed = true
		btn.pressed.connect(_on_time_filter_pressed.bind(_time_presets[preset_name], btn))
		_update_time_filter_button_style(btn, preset_name == "All")
		time_filter_container.add_child(btn)
		if preset_name == "All":
			_current_time_filter_button = btn


func _on_filter_gui_input(event: InputEvent, category: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if event.alt_pressed:
			_solo_category(category)
			get_viewport().set_input_as_handled()


func _solo_category(solo_cat: String) -> void:
	# If already soloing this category, toggle show all
	var is_already_soloed := true
	for cat in _active_filters:
		if (
			(cat == solo_cat and not _active_filters[cat])
			or (cat != solo_cat and _active_filters[cat])
		):
			is_already_soloed = false
			break

	_is_rebuilding = true
	for child in filter_container.get_children():
		var btn := child as Button
		if not btn:
			continue

		var should_be_pressed := true if is_already_soloed else (btn.text == solo_cat)
		if btn.button_pressed != should_be_pressed:
			btn.button_pressed = should_be_pressed
		else:
			# Manually update state if button was already in desired state
			_active_filters[btn.text] = should_be_pressed
			_update_button_style(btn, should_be_pressed)

	_is_rebuilding = false
	_rebuild_log_display()


func _on_filter_toggled(is_pressed: bool, category: String, btn: Button) -> void:
	_active_filters[category] = is_pressed
	_update_button_style(btn, is_pressed)
	if not _is_rebuilding:
		_rebuild_log_display()


func _update_button_style(btn: Button, is_pressed: bool) -> void:
	if is_pressed:
		# Use a visible color (e.g. cyan with some alpha) for active filters
		btn.modulate = Color(0.3, 0.8, 1.0, 1.0)
	else:
		# Reset to default
		btn.modulate = Color(1, 1, 1, 0.5)


func _update_time_filter_button_style(btn: Button, is_active: bool) -> void:
	if is_active:
		# Use a green color for active time filter
		btn.modulate = Color(0.3, 1.0, 0.3, 1.0)
	else:
		# Reset to default
		btn.modulate = Color(1, 1, 1, 0.5)


func _on_time_filter_pressed(duration: float, button: Button) -> void:
	# Update previous button style
	if _current_time_filter_button:
		_update_time_filter_button_style(_current_time_filter_button, false)

	# Set new active filter
	_active_time_filter = duration
	_current_time_filter_button = button
	_update_time_filter_button_style(button, true)
	_rebuild_log_display()


func _append_formatted_log(log_data: Dictionary) -> void:
	if log_display:
		var bbcode_msg := _format_log(log_data)
		log_display.append_text(bbcode_msg + "\n")


func _format_log(log_data: Dictionary) -> String:
	var time: float = log_data.get("time", 0.0)
	var frame: int = log_data.get("frame", 0)
	var formatted_msg: String = (
		"[%7.3fs][F:%d][%s] %s %s - [%s] %s"
		% [
			time,
			frame,
			log_data.get("prefix", ""),
			log_data.get("context_str", ""),
			log_data.get("category", ""),
			log_data.get("level", ""),
			log_data.get("message", "")
		]
	)

	var level: String = log_data.get("level", "DEBUG")

	match level:
		"DEBUG":
			return "[color=gray]{0}[/color]".format([formatted_msg])
		"INFO":
			return "[b][color=cyan]{0}[/color][/b]".format([formatted_msg])
		"WARN":
			return "[b][color=yellow]{0}[/color][/b]".format([formatted_msg])
		"ERROR":
			return "[b][color=red]{0}[/color][/b]".format([formatted_msg])
	return formatted_msg


func _get_max_log_time() -> float:
	if _all_logs.is_empty():
		return 0.0
	return _all_logs[-1].get("time", 0.0)


func _should_display_log(log_data: Dictionary) -> bool:
	# Check category filter
	var category: String = log_data.get("category", "")
	if category.is_empty():
		category = "Default"

	if not _active_filters.get(category, true):
		return false

	# Check time filter
	if _active_time_filter > 0.0:
		var log_time: float = log_data.get("time", 0.0)
		var max_time: float = _get_max_log_time()
		if max_time - log_time > _active_time_filter:
			return false

	return true


func _rebuild_log_display() -> void:
	log_display.clear()
	for log_data: Dictionary in _all_logs:
		if _should_display_log(log_data):
			_append_formatted_log(log_data)


func _on_clear_pressed() -> void:
	_all_logs.clear()
	log_display.clear()
	# Optionally clear filters too?
	for child: Node in filter_container.get_children():
		child.queue_free()
	_active_filters.clear()

	# Reset time filter to "All"
	_active_time_filter = -1.0
	if _current_time_filter_button:
		_update_time_filter_button_style(_current_time_filter_button, false)

	# Find and activate the "All" button
	for child: Node in time_filter_container.get_children():
		var btn := child as Button
		if btn and btn.text == "All":
			_current_time_filter_button = btn
			_update_time_filter_button_style(btn, true)
			break


# ------------- [Public Method] -------------
## stream logs from outside (legacy/raw string support)
func append_log(bbcode_text: String) -> void:
	if log_display:
		log_display.append_text(bbcode_text + "\n")


## add log with data for filtering
func add_log(log_data: Dictionary) -> void:
	_all_logs.append(log_data)

	var category: String = log_data.get("category", "")
	if category.is_empty():
		category = "Default"

	if not _active_filters.has(category):
		_add_filter_button(category)

	if _should_display_log(log_data):
		_append_formatted_log(log_data)
