@tool
extends Control

const MAX_LOG_COUNT = 10000
const LOG_TRIM_BATCH_SIZE = 100

# ------------- [Private Variable] -------------
var _all_logs: Array[Dictionary] = []
# category (String) -> is_active (bool)
var _active_filters: Dictionary[String, bool] = {}
var _search_query: String = ""
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
var _is_right_dragging: bool = false
var _selected_log_indices: Dictionary = {}
var _ctrl_held: bool = false
# Maps display line number to log array index
var _displayed_line_map: Array[int] = []

# Drag-to-select state
var _is_dragging_selection: bool = false
var _drag_anchor_display_line: int = -1
var _drag_is_additive: bool = false
var _drag_last_range: Vector2i = Vector2i(-1, -1)
var _drag_moved: bool = false

@onready var clear_button: Button = %ClearButton
@onready var copy_button: Button = %CopyButton
@onready var save_button: Button = %SaveButton
@onready var pause_on_error_button: Button = %PauseOnErrorButton
@onready var search_line_edit: LineEdit = %SearchLineEdit
@onready var log_display: RichTextLabel = %RichTextLabel
@onready var filter_container: HBoxContainer = %FilterContainer
@onready var time_filter_container: HBoxContainer = %TimeFilterContainer
@onready var level_filter_container: HBoxContainer = %LevelFilterContainer


# ------------- [Callbacks] -------------
func _ready() -> void:
	clear_button.pressed.connect(_on_clear_pressed)
	copy_button.pressed.connect(_on_copy_pressed)
	save_button.pressed.connect(_on_save_pressed)
	pause_on_error_button.toggled.connect(_on_pause_on_error_toggled)
	search_line_edit.text_changed.connect(_on_search_text_changed)

	log_display.bbcode_enabled = true
	# enable automatic scrolling
	log_display.scroll_following = true
	log_display.meta_clicked.connect(_on_log_meta_clicked)
	log_display.gui_input.connect(_on_log_display_gui_input)

	# Assign shortcuts
	_setup_shortcuts()

	_add_time_filter_buttons()
	_add_level_filter_buttons()

	visibility_changed.connect(_on_visibility_changed)

	# Set focus_mode so this panel can receive input
	focus_mode = Control.FOCUS_ALL

	if Engine.is_editor_hint():
		_update_pause_on_error_button()
		var es := EditorInterface.get_editor_settings()
		es.settings_changed.connect(_update_pause_on_error_button)


func _input(event: InputEvent) -> void:
	# Handle Ctrl+C (copy) here, in _input (before _shortcut_input / _unhandled_input),
	# because the editor's own input chain tends to consume Ctrl+C before it reaches
	# the button's Shortcut or _unhandled_input. Marking the event as handled here
	# stops it from being swallowed by anything else.
	if not is_visible_in_tree():
		return
	if not (event is InputEventKey and event.pressed and not event.is_echo()):
		return
	if not (event.ctrl_pressed or event.command_or_control_autoremap):
		return
	if event.keycode != KEY_C:
		return
	# Don't steal Ctrl+C from text editing controls (e.g. search box, script editor).
	var focused := get_window().gui_get_focus_owner()
	if focused is LineEdit or focused is TextEdit:
		return
	_on_copy_pressed()
	get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	# Only process shortcuts when panel is visible
	if not visible:
		return

	# Escape clears selection (works even without focus on panel)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if not _selected_log_indices.is_empty():
			_selected_log_indices.clear()
			_update_selection_info()
			_rebuild_log_display()
			get_viewport().set_input_as_handled()
			return

	# Check if focus is within this panel or its children
	var focused_control: Control = get_window().gui_get_focus_owner()
	if not focused_control:
		return
	if focused_control != self and not is_ancestor_of(focused_control):
		return

	if event is InputEventKey and event.pressed:
		if (event.ctrl_pressed or event.command_or_control_autoremap) and event.keycode == KEY_F:
			search_line_edit.grab_focus()
			search_line_edit.select_all()
			get_viewport().set_input_as_handled()
			return

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


func _on_visibility_changed() -> void:
	if not visible:
		_is_right_dragging = false
		if log_display:
			log_display.mouse_default_cursor_shape = Control.CURSOR_ARROW


# ------------- [Public Method called by Debugger Plugin] -------------
func add_log(log_data: Dictionary) -> void:
	var tags := _get_log_tags(log_data)
	log_data["_log_tags"] = tags

	# Add new category buttons if they don't exist yet
	for tag in tags:
		if not _active_filters.has(tag):
			_add_filter_button(tag)

	# --- Log Stacking Logic ---
	var is_stacked := false
	if not _all_logs.is_empty():
		var last_log: Dictionary = _all_logs[-1]
		# Check if current log is identical to the last one (excluding time/frame/count)
		if (
			last_log.get("message") == log_data.get("message")
			and last_log.get("level") == log_data.get("level")
			and last_log.get("prefix") == log_data.get("prefix")
			and last_log.get("category") == log_data.get("category")
			and last_log.get("caller_info") == log_data.get("caller_info")
		):
			last_log["count"] = last_log.get("count", 1) + 1
			# Update time/frame to the latest one
			last_log["time"] = log_data.get("time", 0.0)
			last_log["frame"] = log_data.get("frame", 0)
			is_stacked = true

	if not is_stacked:
		log_data["count"] = 1
		_all_logs.append(log_data)

	# Limit the number of logs stored
	if _all_logs.size() > MAX_LOG_COUNT:
		# Trim a batch of logs to avoid rebuilding too frequently
		_all_logs = _all_logs.slice(LOG_TRIM_BATCH_SIZE)
		# Selection indices are invalidated by trimming
		_selected_log_indices.clear()
		_update_selection_info()
		_rebuild_log_display()
		return  # Display already rebuilt, no need to append

	if _should_display_log(log_data):
		var log_idx := _all_logs.size() - 1
		if is_stacked:
			# Update only the last visible line
			var pc := log_display.get_paragraph_count()
			if pc > 0:
				log_display.remove_paragraph(pc - 1)
			# Update the last entry in the line map
			if not _displayed_line_map.is_empty():
				_displayed_line_map[-1] = log_idx
			_append_formatted_log(log_data, log_idx)
		else:
			_displayed_line_map.append(log_idx)
			_append_formatted_log(log_data, log_idx)


# ------------- [Private Method] -------------
func _get_log_tags(log_data: Dictionary) -> Array[String]:
	var category: String = log_data.get("category", "")
	if not category.is_empty():
		var tags: Array[String] = []
		for tag in category.split("|"):
			var t := tag.strip_edges()
			if not t.is_empty():
				tags.append(t)
		if not tags.is_empty():
			return tags

	var prefix: String = log_data.get("prefix", "")
	if not prefix.is_empty() and prefix != DLoggerConstants.DEFAULT_PREFIX:
		return [prefix]

	return ["Default"]


func _setup_shortcuts() -> void:
	# Ctrl + L (or Cmd + L) to clear logs
	clear_button.shortcut = _create_shortcut(KEY_L, true)
	clear_button.tooltip_text = "Clear Logs (Ctrl+L)"

	# Ctrl + C (or Cmd + C) to copy logs
	copy_button.shortcut = _create_shortcut(KEY_C, true)
	copy_button.tooltip_text = "Copy Logs (Ctrl+C)"

	# Ctrl + Alt + S (or Cmd + Alt + S) to save logs
	save_button.shortcut = _create_shortcut(KEY_S, true, false, true)
	save_button.tooltip_text = "Save Logs (Ctrl+Alt+S)"


## Helper function to dynamically generate shortcut resources
func _create_shortcut(
	p_keycode: Key,
	p_require_ctrl: bool = false,
	p_require_shift: bool = false,
	p_require_alt: bool = false
) -> Shortcut:
	var shortcut := Shortcut.new()
	var event := InputEventKey.new()

	event.keycode = p_keycode

	if p_require_ctrl:
		# Require Cmd key on macOS, Ctrl key on other OS
		if OS.get_name() == "macOS":
			event.command = true
		else:
			event.ctrl_pressed = true

	if p_require_shift:
		event.shift_pressed = true

	if p_require_alt:
		event.alt_pressed = true

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


func _apply_level_filter(_min_level: int, preset_name: String) -> void:
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


func _update_pause_on_error_button_style(is_active: bool) -> void:
	if is_active:
		# Use a red/orange color for pause on error active
		pause_on_error_button.modulate = Color(1.0, 0.4, 0.3, 1.0)
	else:
		# Reset to default
		pause_on_error_button.modulate = Color(1, 1, 1, 0.5)


func _update_pause_on_error_button() -> void:
	if not Engine.is_editor_hint():
		return
	var es := EditorInterface.get_editor_settings()
	if es.has_setting(DLoggerConstants.EDITOR_SETTING_PAUSE_ON_ERROR):
		var val: bool = es.get_setting(DLoggerConstants.EDITOR_SETTING_PAUSE_ON_ERROR)
		if pause_on_error_button.button_pressed != val:
			pause_on_error_button.set_pressed_no_signal(val)
		_update_pause_on_error_button_style(val)


func _on_pause_on_error_toggled(is_pressed: bool) -> void:
	if not Engine.is_editor_hint():
		return
	var es := EditorInterface.get_editor_settings()
	var current_val: bool = es.get_setting(DLoggerConstants.EDITOR_SETTING_PAUSE_ON_ERROR)
	if current_val != is_pressed:
		es.set_setting(DLoggerConstants.EDITOR_SETTING_PAUSE_ON_ERROR, is_pressed)
	_update_pause_on_error_button_style(is_pressed)


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


func _on_log_display_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_ctrl_held = (event.ctrl_pressed or event.command_or_control_autoremap)

		if event.button_index == MOUSE_BUTTON_LEFT:
			# Grab focus so subsequent keyboard shortcuts (e.g. Ctrl+C) work
			grab_focus()

			if event.pressed:
				var line_idx := _get_line_at_mouse_pos(event.position)
				if line_idx >= 0 and line_idx < _displayed_line_map.size():
					if _ctrl_held:
						# Ctrl+Click: toggle single line (existing behavior)
						# then any subsequent drag will be additive.
						_toggle_log_selection(_displayed_line_map[line_idx])
						_drag_is_additive = true
					else:
						# Plain click: just start drag tracking.
						# Selection only happens on drag, not click.
						_drag_is_additive = false

					_drag_anchor_display_line = line_idx
					_is_dragging_selection = true
					_drag_moved = false
					_drag_last_range = Vector2i(line_idx, line_idx)
				else:
					# Click outside any log line: clear selection.
					if not _ctrl_held:
						if not _selected_log_indices.is_empty():
							_selected_log_indices.clear()
							_update_selection_info()
							_rebuild_log_display_preserve_scroll()
					_is_dragging_selection = false

				get_viewport().set_input_as_handled()
				return

			else:
				# Left button released
				if _is_dragging_selection:
					if not _drag_moved and not _ctrl_held:
						# Pure click (no drag, no Ctrl): clear selection.
						if not _selected_log_indices.is_empty():
							_selected_log_indices.clear()
							_update_selection_info()
							_rebuild_log_display_preserve_scroll()
					_is_dragging_selection = false
					_drag_last_range = Vector2i(-1, -1)
					return

		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				_is_right_dragging = true
				log_display.mouse_default_cursor_shape = Control.CURSOR_DRAG
			else:
				_is_right_dragging = false
				log_display.mouse_default_cursor_shape = Control.CURSOR_ARROW
			accept_event()

	if event is InputEventMouseMotion and _is_right_dragging:
		var v_scroll := log_display.get_v_scroll_bar()
		if v_scroll:
			v_scroll.value -= event.relative.y
		accept_event()

	# Drag-to-select: update range while left mouse is held.
	if (
		event is InputEventMouseMotion
		and _is_dragging_selection
		and (event.button_mask & MOUSE_BUTTON_MASK_LEFT)
	):
		_drag_moved = true
		var current_line := _get_line_at_mouse_pos(event.position)
		if current_line >= 0 and current_line < _displayed_line_map.size():
			var range_start := mini(_drag_anchor_display_line, current_line)
			var range_end := maxi(_drag_anchor_display_line, current_line)

			# Skip if the range hasn't changed.
			if range_start == _drag_last_range.x and range_end == _drag_last_range.y:
				return

			_drag_last_range = Vector2i(range_start, range_end)

			if not _drag_is_additive:
				_selected_log_indices.clear()

			for dl in range(range_start, range_end + 1):
				_selected_log_indices[_displayed_line_map[dl]] = true

			_update_selection_info()
			_rebuild_log_display_preserve_scroll()
			accept_event()


func _get_line_at_mouse_pos(mouse_pos: Vector2) -> int:
	# event.position from gui_input is already in the control's local
	# coordinates. The RichTextLabel's stylebox has content margins
	# (padding) inside its bounds. get_paragraph_offset() is relative to
	# the content area AFTER those margins, so we must subtract the top
	# margin to convert from local coordinates to content coordinates.
	var v_scroll := log_display.get_v_scroll_bar()
	var scroll_y := v_scroll.value if v_scroll else 0.0

	# Calculate Y position relative to the top of the content
	var style := log_display.get_theme_stylebox(&"normal")
	var top_padding := style.content_margin_top if style else 0.0
	var content_y := mouse_pos.y + scroll_y - top_padding

	# Iterate paragraphs to find which one contains content_y
	var count := log_display.get_paragraph_count()
	for i in range(count - 1, -1, -1):
		if content_y >= log_display.get_paragraph_offset(i):
			return i
	return -1


func _on_log_meta_clicked(meta: Variant) -> void:
	if meta is String:
		var meta_str: String = meta

		# Handle selection toggle
		if meta_str.begins_with("select:"):
			if _ctrl_held:
				var log_index := meta_str.trim_prefix("select:").to_int()
				_toggle_log_selection(log_index)
			return

		if meta_str.begins_with("filter:"):
			_solo_category(meta_str.trim_prefix("filter:"))
			return

		var parts := meta_str.split(":")
		if parts.size() >= 3:
			# コロンで分割された要素のうち、最後（行番号）を除いた全てを結合してパスを復元
			var path_parts := parts.slice(0, -1)
			var file_path := ":".join(path_parts)
			var line_num := parts[-1].to_int()

			if FileAccess.file_exists(file_path):
				var res := load(file_path)
				if res is Script:
					EditorInterface.edit_script(res, line_num)


func _toggle_log_selection(log_index: int) -> void:
	if _selected_log_indices.has(log_index):
		_selected_log_indices.erase(log_index)
	else:
		_selected_log_indices[log_index] = true
	_update_selection_info()
	_rebuild_log_display_preserve_scroll()


func _update_selection_info() -> void:
	var count := _selected_log_indices.size()
	if count > 0:
		copy_button.tooltip_text = ("Copy Selected (%d) (Ctrl+C)\nEsc: Clear" % count)
	else:
		copy_button.tooltip_text = ("Copy Logs (Ctrl+C)")


func _append_formatted_log(log_data: Dictionary, log_index: int = -1) -> void:
	if log_display:
		var is_selected := log_index >= 0 and _selected_log_indices.has(log_index)
		var bbcode_msg := _format_log(log_data, is_selected)
		if is_selected:
			bbcode_msg = "[bgcolor=#44686868]%s[/bgcolor]" % bbcode_msg
		log_display.append_text(bbcode_msg + "\n")


func _format_log(log_data: Dictionary, is_selected: bool = false) -> String:
	var time: float = log_data.get("time", 0.0)
	var frame: int = log_data.get("frame", 0)
	var level: String = log_data.get("level", "DEBUG")
	var prefix: String = log_data.get("prefix", "")
	var category: String = log_data.get("category", "")
	var context_str: String = log_data.get("context_str", "")
	var caller_info = log_data.get("caller_info", {})

	# Use source string formatting with clickable BBCode.
	var source_str := DLoggerFunc.get_source_string(prefix, category, true)

	var formatted_msg := DLoggerFunc.get_formatted_line(
		time, frame, source_str, caller_info, context_str, level, log_data.get("message", ""), true
	)

	var count: int = log_data.get("count", 1)
	if count > 1:
		formatted_msg += " [b](x%d)[/b]" % count

	var text_color := ""
	if is_selected:
		text_color = "#ffffff"
	else:
		match level:
			"DEBUG":
				text_color = "gray"
			"INFO":
				text_color = "cyan"
			"WARN":
				text_color = "yellow"
			"ERROR":
				text_color = "red"

	var result: String
	if is_selected:
		result = ("[b][color={0}]{1}[/color][/b]".format([text_color, formatted_msg]))
	elif not text_color.is_empty():
		var is_bold := level in ["INFO", "WARN", "ERROR"]
		if is_bold:
			result = ("[b][color={0}]{1}[/color][/b]".format([text_color, formatted_msg]))
		else:
			result = ("[color={0}]{1}[/color]".format([text_color, formatted_msg]))
	else:
		result = formatted_msg

	return result


func _get_max_log_time() -> float:
	if _all_logs.is_empty():
		return 0.0
	return _all_logs[-1].get("time", 0.0)


func _get_log_level_value(level_str: String) -> int:
	return _log_level_values.get(level_str, 0)


func _should_display_log(log_data: Dictionary) -> bool:
	# Check category/prefix filter (OR logic: show if at least one tag is active)
	var tags: Array[String] = log_data.get("_log_tags", [])
	if tags.is_empty():
		tags = _get_log_tags(log_data)
	var is_tag_active := false
	for tag in tags:
		if _active_filters.get(tag, true):
			is_tag_active = true
			break
	if not is_tag_active:
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

	# Check search query
	if not _search_query.is_empty():
		var query := _search_query.to_lower()
		var message: String = log_data.get("message", "").to_lower()
		var category: String = log_data.get("category", "").to_lower()
		var prefix: String = log_data.get("prefix", "").to_lower()

		if not (query in message or query in category or query in prefix):
			return false

	return true


func _rebuild_log_display() -> void:
	log_display.clear()
	_displayed_line_map.clear()
	for i in range(_all_logs.size()):
		var log_data: Dictionary = _all_logs[i]
		if _should_display_log(log_data):
			_displayed_line_map.append(i)
			_append_formatted_log(log_data, i)


## Rebuilds the log display while preserving the current scroll position.
## Call this instead of _rebuild_log_display() when the user has actively
## positioned the viewport (e.g. after a selection change).
func _rebuild_log_display_preserve_scroll() -> void:
	var v_scroll := log_display.get_v_scroll_bar()
	var saved_scroll: float = v_scroll.value if v_scroll else 0.0
	log_display.scroll_following = false
	_rebuild_log_display()
	if v_scroll:
		# Defer scroll restoration so the layout has settled and the
		# scroll bar's max_value reflects the new content height.
		# Without this, the first selection can jump the viewport.
		v_scroll.call_deferred("set_value", saved_scroll)


func _on_search_text_changed(new_text: String) -> void:
	_search_query = new_text
	_rebuild_log_display()


func clear_logs() -> void:
	_all_logs.clear()
	_selected_log_indices.clear()
	log_display.clear()

	for child: Node in filter_container.get_children():
		child.queue_free()
	_active_filters.clear()

	# Reset search
	_search_query = ""
	search_line_edit.text = ""

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

	_update_selection_info()


func _on_clear_pressed() -> void:
	clear_logs()


func _on_copy_pressed() -> void:
	var formatted_logs: String = _get_formatted_logs()
	if formatted_logs.is_empty():
		return
	var copy_count := _selected_log_indices.size() if not _selected_log_indices.is_empty() else _displayed_line_map.size()
	_copy_to_clipboard(formatted_logs, copy_count)


func _get_formatted_logs() -> String:
	var output_text := ""
	var has_selection := not _selected_log_indices.is_empty()
	for i in range(_all_logs.size()):
		var log_data: Dictionary = _all_logs[i]
		# Skip if selection exists and this log is not selected
		if has_selection and not _selected_log_indices.has(i):
			continue
		if _should_display_log(log_data):
			var time: float = log_data.get("time", 0.0)
			var frame: int = log_data.get("frame", 0)
			var level: String = log_data.get("level", "DEBUG")
			var prefix: String = log_data.get("prefix", "")
			var category: String = log_data.get("category", "")
			var context_str: String = log_data.get("context_str", "")
			var caller_info = log_data.get("caller_info", {})

			var source_str := DLoggerFunc.get_source_string(prefix, category)

			var raw_msg := DLoggerFunc.get_formatted_line(
				time,
				frame,
				source_str,
				caller_info,
				context_str,
				level,
				log_data.get("message", ""),
				false  # use_bbcode
			)
			output_text += raw_msg + "\n"
	return output_text


func _copy_to_clipboard(text: String, log_count: int = 0) -> void:
	DisplayServer.clipboard_set(text)

	var toast_msg := "Copied %d log(s)" % log_count if log_count > 0 else "Copied"
	_show_toast(toast_msg)

	var original_text := copy_button.text
	copy_button.text = "Copied!"
	await get_tree().create_timer(1.0).timeout
	copy_button.text = original_text


func _show_toast(message: String) -> void:
	var margin := 12
	var toast_w := 220
	var toast_h := 36

	var panel := Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_toast_stylebox())
	panel.size = Vector2(toast_w, toast_h)

	var label := Label.new()
	label.text = message
	label.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))
	label.add_theme_font_size_override("font_size", 14)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel.add_child(label)

	add_child(panel)
	panel.move_to_front()

	# Position and animate after layout is computed
	call_deferred("_animate_toast", panel, margin, toast_w, toast_h)


func _animate_toast(panel: Panel, margin: float, w: float, h: float) -> void:
	if not is_inside_tree():
		panel.queue_free()
		return

	# Set position at bottom-center
	panel.position = Vector2(
		(size.x - w) * 0.5,
		size.y - h - margin
	)

	# Slide up and fade out
	var tween := panel.create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "position:y", panel.position.y - 20, 1.5)
	tween.tween_property(panel, "modulate:a", 0.0, 1.0).set_delay(0.5)
	tween.finished.connect(panel.queue_free)


func _make_toast_stylebox() -> StyleBoxFlat:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.12, 0.12, 0.17, 0.92)
	bg.shadow_color = Color(0, 0, 0, 0.4)
	bg.shadow_size = 4
	bg.corner_radius_top_left = 6
	bg.corner_radius_top_right = 6
	bg.corner_radius_bottom_left = 6
	bg.corner_radius_bottom_right = 6
	bg.content_margin_left = 16
	bg.content_margin_right = 16
	bg.content_margin_top = 6
	bg.content_margin_bottom = 6
	return bg


func _on_save_pressed() -> void:
	var formatted_logs: String = _get_formatted_logs()
	if formatted_logs.is_empty():
		return

	# Generate filename with timestamp
	var now = Time.get_datetime_dict_from_system()
	var filename = (
		"logs_%04d%02d%02d_%02d%02d%02d.txt"
		% [now.year, now.month, now.day, now.hour, now.minute, now.second]
	)

	# Save to user:// directory (project user data directory)
	var file_path = "user://%s" % filename
	var result = _save_to_file(file_path, formatted_logs)

	if result == OK:
		var original_text := save_button.text
		save_button.text = "Saved!"
		await get_tree().create_timer(1.0).timeout
		save_button.text = original_text
	else:
		push_error("Failed to save logs to %s" % file_path)


func _save_to_file(file_path: String, content: String) -> int:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	return OK
