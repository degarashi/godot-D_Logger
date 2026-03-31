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

# Log level filtering
var _log_levels: Array[String] = ["DEBUG", "INFO", "WARN", "ERROR"]
var _log_level_values: Dictionary[String, int] = {"DEBUG": 0, "INFO": 1, "WARN": 2, "ERROR": 3}
var _level_presets: Dictionary[String, int] = {"DEBUG": 0, "INFO+": 1, "WARN+": 2, "ERROR": 3}
var _active_level_filter: int = 0
var _current_level_filter_button: Button = null

@onready var clear_button: Button = %ClearButton
@onready var copy_button: Button = %CopyButton
@onready var log_display: RichTextLabel = %RichTextLabel
@onready var filter_container: HBoxContainer = %FilterContainer
@onready var time_filter_container: HBoxContainer = %TimeFilterContainer
@onready var level_filter_container: HBoxContainer = %LevelFilterContainer


# ------------- [Callbacks] -------------
func _ready() -> void:
	clear_button.pressed.connect(_on_clear_pressed)
	copy_button.pressed.connect(_on_copy_pressed)
	log_display.bbcode_enabled = true
	# enable automatic scrolling
	log_display.scroll_following = true

	# Assign shortcuts
	_setup_shortcuts()

	_add_time_filter_buttons()
	_add_level_filter_buttons()

	# Set focus_mode so this panel can receive input
	focus_mode = Control.FOCUS_ALL


func _unhandled_input(event: InputEvent) -> void:
	# Only process shortcuts when panel is visible
	if not visible:
		return

	# Check if focus is within this panel or its children
	var focused_control: Control = get_window().gui_get_focus_owner()
	if not focused_control:
		return
	if focused_control != self and not is_ancestor_of(focused_control):
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_apply_level_filter(0, "DEBUG")  # DEBUG
				get_viewport().set_input_as_handled()
			KEY_2:
				_apply_level_filter(1, "INFO+")  # INFO+
				get_viewport().set_input_as_handled()
			KEY_3:
				_apply_level_filter(2, "WARN+")  # WARN+
				get_viewport().set_input_as_handled()
			KEY_4:
				_apply_level_filter(3, "ERROR")  # ERROR
				get_viewport().set_input_as_handled()


# ------------- [Public Method called by Debugger Plugin] -------------
func add_log(log_data: Dictionary) -> void:
	var category: String = log_data.get("category", "")
	if category.is_empty():
		category = "Default"

	# Add new category button if it doesn't exist yet
	if not _active_filters.has(category):
		_add_filter_button(category)

	_all_logs.append(log_data)

	if _should_display_log(log_data):
		_append_formatted_log(log_data)


# ------------- [Private Method] -------------
func _setup_shortcuts() -> void:
	# Ctrl + L (or Cmd + L) to clear logs
	clear_button.shortcut = _create_shortcut(KEY_L, true)
	clear_button.tooltip_text = "Clear Logs (Ctrl+L)"

	# Ctrl + C (or Cmd + C) to copy logs
	copy_button.shortcut = _create_shortcut(KEY_C, true)
	copy_button.tooltip_text = "Copy Logs (Ctrl+C)"


## Helper function to dynamically generate shortcut resources
func _create_shortcut(p_keycode: Key, p_require_ctrl: bool = false) -> Shortcut:
	var shortcut := Shortcut.new()
	var event := InputEventKey.new()

	event.keycode = p_keycode

	if p_require_ctrl:
		# Require Cmd key on macOS, Ctrl key on other OS
		if OS.get_name() == "macOS":
			event.command = true
		else:
			event.ctrl_pressed = true

	shortcut.events.append(event)
	return shortcut


func _add_filter_button(category: String) -> void:
	_active_filters[category] = true
	var btn := Button.new()
	btn.text = category
	btn.toggle_mode = true
	btn.button_pressed = true
	btn.toggled.connect(_on_filter_toggled.bind(category, btn))
	btn.gui_input.connect(_on_filter_gui_input.bind(category))
	btn.tooltip_text = "Toggle filter | Alt+Click to solo"
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


func _add_level_filter_buttons() -> void:
	for preset_name: String in _level_presets.keys():
		var btn := Button.new()
		btn.text = preset_name
		btn.toggle_mode = true
		if preset_name == "DEBUG":
			btn.button_pressed = true
		btn.pressed.connect(_on_level_filter_pressed.bind(_level_presets[preset_name], btn))
		_update_level_filter_button_style(btn, preset_name == "DEBUG")

		# Add keyboard shortcut hint to tooltip
		var shortcut_hint: String = ""
		match preset_name:
			"DEBUG":
				shortcut_hint = " (Press 1)"
			"INFO+":
				shortcut_hint = " (Press 2)"
			"WARN+":
				shortcut_hint = " (Press 3)"
			"ERROR":
				shortcut_hint = " (Press 4)"
		btn.tooltip_text = preset_name + shortcut_hint

		level_filter_container.add_child(btn)
		if preset_name == "DEBUG":
			_current_level_filter_button = btn


func _apply_level_filter(min_level: int, preset_name: String) -> void:
	for child: Node in level_filter_container.get_children():
		var btn := child as Button
		if btn and btn.text == preset_name:
			btn.pressed.emit()
			break


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


func _update_level_filter_button_style(btn: Button, is_active: bool) -> void:
	if is_active:
		# Use an orange color for active level filter
		btn.modulate = Color(1.0, 0.7, 0.3, 1.0)
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


func _on_level_filter_pressed(min_level: int, button: Button) -> void:
	# Update previous button style
	if _current_level_filter_button:
		_update_level_filter_button_style(_current_level_filter_button, false)

	# Set new active filter
	_active_level_filter = min_level
	_current_level_filter_button = button
	_update_level_filter_button_style(button, true)
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


func _get_log_level_value(level_str: String) -> int:
	return _log_level_values.get(level_str, 0)


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

	# Check level filter
	var log_level_str: String = log_data.get("level", "DEBUG")
	var log_level_val: int = _get_log_level_value(log_level_str)
	if log_level_val < _active_level_filter:
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

	# Find and activate the "All" button for time filter
	for child: Node in time_filter_container.get_children():
		var btn := child as Button
		if btn and btn.text == "All":
			_current_time_filter_button = btn
			_update_time_filter_button_style(btn, true)
			break

	# Reset level filter to "DEBUG"
	_active_level_filter = 0
	if _current_level_filter_button:
		_update_level_filter_button_style(_current_level_filter_button, false)

	# Find and activate the "DEBUG" button for level filter
	for child: Node in level_filter_container.get_children():
		var btn := child as Button
		if btn and btn.text == "DEBUG":
			_current_level_filter_button = btn
			_update_level_filter_button_style(btn, true)
			break


func _on_copy_pressed() -> void:
	var formatted_logs: String = _get_formatted_logs()
	if formatted_logs.is_empty():
		return
	_copy_to_clipboard(formatted_logs)


func _get_formatted_logs() -> String:
	var output_text := ""
	for log_data: Dictionary in _all_logs:
		if _should_display_log(log_data):
			var time: float = log_data.get("time", 0.0)
			var frame: int = log_data.get("frame", 0)
			var raw_msg: String = (
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
			output_text += raw_msg + "\n"
	return output_text


func _copy_to_clipboard(text: String) -> void:
	DisplayServer.clipboard_set(text)

	var original_text := copy_button.text
	copy_button.text = "Copied!"
	await get_tree().create_timer(1.0).timeout
	copy_button.text = original_text
