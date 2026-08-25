@tool
extends Control

const MAX_LOG_COUNT = 10000
const LOG_TRIM_BATCH_SIZE = 100

const MIN_FONT_SIZE := 8
const MAX_FONT_SIZE := 32
const DEFAULT_FONT_SIZE := 14
const FONT_SIZE_STEP := 2
const EDITOR_SETTING_FONT_SIZE := "d_logger/panel_font_size"
const EDITOR_SETTING_LEVEL_FILTER := "d_logger/panel_level_filter"
const SEARCH_DEBOUNCE_SECONDS := 0.2

# Matches the legacy baked-in selection bgcolor (#44686868, #RRGGBBAA).
const SELECTION_HIGHLIGHT_COLOR := Color(0.267, 0.408, 0.408, 0.408)

# ------------- [Private Variable] -------------
var _log_font_size: int = DEFAULT_FONT_SIZE
var _all_logs: Array[Dictionary] = []
# category (String) -> is_active (bool)
var _active_filters: Dictionary[String, bool] = {}
var _search := DLoggerSearch.new()
# Incremented on every search input; a pending debounced rebuild is superseded
# when the token it captured no longer matches.
var _search_rebuild_token := 0
var _is_rebuilding: bool = false
# Time presets: name -> duration in seconds (-1.0 = show all)
var _time_presets: Dictionary[String, float] = {
	"All": -1.0, "30s": 30.0, "1m": 60.0, "5m": 300.0
}
var _active_time_filter: float = -1.0

# Log level filtering
var _log_level_values: Dictionary[String, int] = {
	"DEBUG": 0, "INFO": 1, "WARN": 2, "ERROR": 3
}
var _level_presets: Dictionary[String, int] = {
	"DEBUG": 0, "INFO+": 1, "WARN+": 2, "ERROR": 3
}
var _active_level_filter: int = 0
var _is_right_dragging: bool = false
var _selected_log_indices: Dictionary = {}
# log index -> display paragraph index; the inverse of _displayed_line_map,
# rebuilt alongside it so the selection overlay can locate paragraphs
# without scanning every displayed line.
var _log_to_display_map: Dictionary = {}
# Translucent row highlight drawn above log_display. Selection state lives
# entirely outside the RichTextLabel document: baking [bgcolor] into each
# selected line forced clear() + re-append of the whole document on every
# drag motion, which dominated frame time once logs reached ~1000 lines.
var _selection_overlay: Control = null
var _ctrl_held: bool = false
# Smart auto-scroll: tracks whether the user is at the bottom of the log view
var _is_auto_scrolling: bool = true
# Maps display line number to log array index
var _displayed_line_map: Array[int] = []
# Coalesces stacked-log display rebuilds into one per frame
var _rebuild_pending: bool = false

# Drag-to-select state
var _is_dragging_selection: bool = false
var _drag_anchor_display_line: int = -1
var _drag_is_additive: bool = false
var _drag_last_range: Vector2i = Vector2i(-1, -1)
var _drag_moved: bool = false

# Hover tooltip state
var _hovered_line_idx: int = -1

# Bracket-pair hover state: {"meta": String, "log": int, "pair": Array} or
# empty while nothing is highlighted. "meta" stores the exact [url] meta of
# the hovered bracket so a late/stale meta_hover_ended can never clear a
# newer highlight that started before it fired.
var _bracket_hover: Dictionary = {}

# Opacity (%) of that highlight, mirrored from the EditorSettings entry
# d_logger/panel_bracket_highlight_opacity and resolved to a #rrggbbaa
# background string through DLoggerPanelFormat.bracket_hover_bg().
var _bracket_highlight_opacity: int = DLoggerConstants.DEFAULT_BRACKET_HIGHLIGHT

@onready var clear_button: Button = %ClearButton
@onready var copy_button: Button = %CopyButton
@onready var save_button: Button = %SaveButton
@onready var pause_on_error_button: Button = %PauseOnErrorButton
@onready var search_line_edit: LineEdit = %SearchLineEdit
@onready var case_sensitive_checkbox: CheckBox = %CaseSensitiveCheckBox
@onready var log_display: RichTextLabel = %RichTextLabel
@onready var filter_container: HFlowContainer = %FilterContainer
@onready var show_all_button: Button = %ShowAllButton
@onready var time_option_button: OptionButton = %TimeOptionButton
@onready var level_option_button: OptionButton = %LevelOptionButton
@onready var word_wrap_checkbox: CheckBox = %WordWrapCheckBox
@onready var regex_checkbox: CheckBox = %RegexCheckBox
@onready var relative_checkbox: CheckBox = %RelativeCheckBox
@onready var stats_label: Label = %StatsLabel

# Per-level displayed count for the stats bar
var _stats_level_counts: Dictionary[String, int] = {
	"DEBUG": 0, "INFO": 0, "WARN": 0, "ERROR": 0
}


# ------------- [Callbacks] -------------
func _ready() -> void:
	clear_button.pressed.connect(_on_clear_pressed)
	copy_button.pressed.connect(_on_copy_pressed)
	save_button.pressed.connect(_on_save_pressed)
	pause_on_error_button.toggled.connect(_on_pause_on_error_toggled)
	search_line_edit.text_changed.connect(_on_search_text_changed)
	case_sensitive_checkbox.toggled.connect(_on_case_sensitive_toggled)
	regex_checkbox.toggled.connect(_on_regex_toggled)
	relative_checkbox.toggled.connect(_on_relative_toggled)

	log_display.bbcode_enabled = true
	log_display.scroll_following = true
	log_display.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
		if word_wrap_checkbox.button_pressed
		else TextServer.AUTOWRAP_OFF
	)
	word_wrap_checkbox.toggled.connect(_on_word_wrap_toggled)
	log_display.meta_clicked.connect(_on_log_meta_clicked)
	log_display.meta_hover_started.connect(_on_bracket_hover_started)
	log_display.meta_hover_ended.connect(_on_bracket_hover_ended)
	log_display.gui_input.connect(_on_log_display_gui_input)
	_setup_selection_overlay()

	# Load and apply saved font size (EditorSettings persists between sessions).
	if Engine.is_editor_hint():
		var es := EditorInterface.get_editor_settings()
		if es.has_setting(EDITOR_SETTING_FONT_SIZE):
			_log_font_size = es.get_setting(EDITOR_SETTING_FONT_SIZE)
	_apply_font_size()

	# Assign shortcuts
	_setup_shortcuts()

	_setup_time_option_button()
	_setup_level_option_button()
	show_all_button.pressed.connect(_on_show_all_pressed)

	visibility_changed.connect(_on_visibility_changed)

	# Set focus_mode so this panel can receive input
	focus_mode = Control.FOCUS_ALL

	if Engine.is_editor_hint():
		_update_pause_on_error_button()
		var es := EditorInterface.get_editor_settings()
		es.settings_changed.connect(_update_pause_on_error_button)
		es.settings_changed.connect(_on_bracket_highlight_setting_changed)
		_refresh_bracket_highlight_setting()


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
	# Only handle when focus is within this panel or its children, so the
	# editor's other docks keep their own Ctrl+C behavior.
	if not focused:
		return
	if focused != self and not is_ancestor_of(focused):
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
			_redraw_selection_overlay()
			get_viewport().set_input_as_handled()
			return

	# Check if focus is within this panel or its children
	var focused_control: Control = get_window().gui_get_focus_owner()
	if not focused_control:
		return
	if focused_control != self and not is_ancestor_of(focused_control):
		return

	if event is InputEventKey and event.pressed:
		if (
			(event.ctrl_pressed or event.command_or_control_autoremap)
			and event.keycode == KEY_F
		):
			search_line_edit.grab_focus()
			search_line_edit.select_all()
			get_viewport().set_input_as_handled()
			return

		match event.keycode:
			KEY_1:
				_apply_level_filter(0)  # DEBUG
				get_viewport().set_input_as_handled()
			KEY_2:
				_apply_level_filter(1)  # INFO+
				get_viewport().set_input_as_handled()
			KEY_3:
				_apply_level_filter(2)  # WARN+
				get_viewport().set_input_as_handled()
			KEY_4:
				_apply_level_filter(3)  # ERROR
				get_viewport().set_input_as_handled()


func _on_visibility_changed() -> void:
	if not visible:
		_is_right_dragging = false
		if log_display:
			log_display.mouse_default_cursor_shape = Control.CURSOR_ARROW
		# Drop any bracket-pair highlight: while hidden no meta_hover_ended
		# fires, so re-showing could otherwise keep a stale pair lit.
		if not _bracket_hover.is_empty():
			_bracket_hover.clear()
			_schedule_display_rebuild()


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
			and last_log.get("context_str") == log_data.get("context_str")
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
		# Bracket-hover state references a log index too
		_bracket_hover.clear()
		_update_selection_info()
		_rebuild_log_display()
		return  # Display already rebuilt, no need to append

	if _should_display_log(log_data):
		var log_idx := _all_logs.size() - 1
		if is_stacked:
			# Only the last line changes, but full rebuild is more reliable
			# than remove_paragraph + append_text, which can cause visual
			# glitches in Godot's RichTextLabel. Coalesce rebuilds so a flood
			# of identical logs doesn't trigger an O(n) rebuild per log.
			_schedule_display_rebuild()
		else:
			_displayed_line_map.append(log_idx)
			# Keep the selection overlay's inverse map in sync: incremental
			# appends never go through _rebuild_log_display, and a stale
			# map makes highlights appear only after the next rebuild.
			_log_to_display_map[log_idx] = _displayed_line_map.size() - 1
			var level := log_data.get("level", "DEBUG")
			_stats_level_counts[level] = _stats_level_counts.get(level, 0) + 1
			_refresh_stats_label()
			# In relative mode every timestamp depends on the latest max
			# time, so the whole display must be rebuilt. Coalesce it like
			# stacked-log updates: rebuilding per incoming log would cost
			# O(n) each and O(n^2) under a log flood.
			if relative_checkbox.button_pressed:
				_schedule_display_rebuild()
			else:
				_append_formatted_log(log_data, log_idx)


# ------------- [Private Method] -------------
func _get_log_tags(log_data: Dictionary) -> Array[String]:
	return DLoggerPanelFormat.get_log_tags(log_data)


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
		# command_or_control_autoremap matches Cmd on macOS, Ctrl on other
		# platforms (InputEventKey has no "command" property in Godot 4.7).
		event.command_or_control_autoremap = true

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


func _setup_time_option_button() -> void:
	time_option_button.clear()
	for preset_name: String in _time_presets.keys():
		var duration := _time_presets[preset_name]
		time_option_button.add_item(preset_name, int(duration))
	time_option_button.selected = 0
	time_option_button.item_selected.connect(_on_time_option_selected)


func _setup_level_option_button() -> void:
	level_option_button.clear()
	for preset_name: String in _level_presets.keys():
		var min_level := _level_presets[preset_name]
		level_option_button.add_item(preset_name, min_level)

	# Add keyboard shortcut hint to tooltip
	for i in level_option_button.item_count:
		var text := level_option_button.get_item_text(i)
		var shortcut_hint := ""
		match text:
			"DEBUG":
				shortcut_hint = " (Press 1)"
			"INFO+":
				shortcut_hint = " (Press 2)"
			"WARN+":
				shortcut_hint = " (Press 3)"
			"ERROR":
				shortcut_hint = " (Press 4)"
		level_option_button.set_item_tooltip(i, text + shortcut_hint)

	# Restore saved level filter from EditorSettings
	var saved_level := 0
	if Engine.is_editor_hint():
		var es := EditorInterface.get_editor_settings()
		if es.has_setting(EDITOR_SETTING_LEVEL_FILTER):
			saved_level = es.get_setting(EDITOR_SETTING_LEVEL_FILTER)
	_active_level_filter = saved_level
	for i in level_option_button.item_count:
		if level_option_button.get_item_id(i) == saved_level:
			level_option_button.select(i)
			break

	level_option_button.item_selected.connect(_on_level_option_selected)


func _apply_level_filter(min_level: int) -> void:
	for i in level_option_button.item_count:
		if level_option_button.get_item_id(i) == min_level:
			level_option_button.select(i)
			# item_selected is NOT emitted by select(), so call handler directly
			_on_level_option_selected(i)
			break


func _on_filter_gui_input(event: InputEvent, category: String) -> void:
	if (
		event is InputEventMouseButton
		and event.pressed
		and event.button_index == MOUSE_BUTTON_LEFT
	):
		if event.alt_pressed:
			_solo_category(category)
			get_viewport().set_input_as_handled()


func _on_show_all_pressed() -> void:
	_is_rebuilding = true
	for cat: String in _active_filters:
		_active_filters[cat] = true
	for child in filter_container.get_children():
		var btn := child as Button
		if not btn:
			continue
		if not btn.button_pressed:
			btn.button_pressed = true
		else:
			_update_button_style(btn, true)
	_is_rebuilding = false
	_rebuild_log_display()


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

		var should_be_pressed := (
			true if is_already_soloed else (btn.text == solo_cat)
		)
		if btn.button_pressed != should_be_pressed:
			btn.button_pressed = should_be_pressed
		else:
			# Manually update state if button was already in desired state
			_active_filters[btn.text] = should_be_pressed
			_update_button_style(btn, should_be_pressed)

	_is_rebuilding = false
	_rebuild_log_display()


func _on_filter_toggled(
	is_pressed: bool, category: String, btn: Button
) -> void:
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
		var val: bool = es.get_setting(
			DLoggerConstants.EDITOR_SETTING_PAUSE_ON_ERROR
		)
		if pause_on_error_button.button_pressed != val:
			pause_on_error_button.set_pressed_no_signal(val)
		_update_pause_on_error_button_style(val)


func _on_pause_on_error_toggled(is_pressed: bool) -> void:
	if not Engine.is_editor_hint():
		return
	var es := EditorInterface.get_editor_settings()
	var current_val: bool = es.get_setting(
		DLoggerConstants.EDITOR_SETTING_PAUSE_ON_ERROR
	)
	if current_val != is_pressed:
		es.set_setting(
			DLoggerConstants.EDITOR_SETTING_PAUSE_ON_ERROR, is_pressed
		)
	_update_pause_on_error_button_style(is_pressed)


func _on_time_option_selected(index: int) -> void:
	var duration := time_option_button.get_item_id(index)
	_active_time_filter = float(duration)
	_rebuild_log_display()


func _on_level_option_selected(index: int) -> void:
	var min_level := level_option_button.get_item_id(index)
	_active_level_filter = min_level
	if Engine.is_editor_hint():
		var es := EditorInterface.get_editor_settings()
		es.set_setting(EDITOR_SETTING_LEVEL_FILTER, min_level)
	_rebuild_log_display()


func _on_log_display_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_ctrl_held = (event.ctrl_pressed or event.command_or_control_autoremap)

		# Ctrl+MouseWheel to adjust font size
		if _ctrl_held and event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				_change_font_size(FONT_SIZE_STEP)
				accept_event()
				return
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_change_font_size(-FONT_SIZE_STEP)
				accept_event()
				return

		# Detect user scroll on the log display — re-check position after
		# mouse wheel or right-drag so auto-scroll re-engages at the bottom.
		if (
			event.pressed
			and (
				event.button_index
				in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]
			)
		):
			call_deferred("_update_auto_scroll_from_scrollbar")

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
					_drag_last_range = Vector2i(-1, -1)
				else:
					# Click outside any log line: clear selection.
					if not _ctrl_held:
						if not _selected_log_indices.is_empty():
							_selected_log_indices.clear()
							_update_selection_info()
							_redraw_selection_overlay()
					_is_dragging_selection = false

				# NOTE: Do NOT call set_input_as_handled() here.
				# It prevents RichTextLabel from emitting meta_clicked,
				# which breaks [url=filter:category] links in log output.
				return

			else:
				# Left button released
				if _is_dragging_selection:
					if not _drag_moved and not _ctrl_held:
						# Pure click (no drag, no Ctrl): clear selection.
						if not _selected_log_indices.is_empty():
							_selected_log_indices.clear()
							_update_selection_info()
							_redraw_selection_overlay()
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
				call_deferred("_update_auto_scroll_from_scrollbar")
			accept_event()

	if event is InputEventMouseMotion and _is_right_dragging:
		var v_scroll := log_display.get_v_scroll_bar()
		if v_scroll:
			v_scroll.value -= event.relative.y
		accept_event()

	# Hover tooltip: update tooltip text when hovering over a log line.
	if (
		event is InputEventMouseMotion
		and not _is_right_dragging
		and not _is_dragging_selection
	):
		var line_idx := _get_line_at_mouse_pos(event.position)
		if line_idx >= 0 and line_idx < _displayed_line_map.size():
			var log_idx := _displayed_line_map[line_idx]
			if log_idx >= 0 and log_idx < _all_logs.size():
				if _hovered_line_idx != line_idx:
					_hovered_line_idx = line_idx
					var full_text := _format_log_plain(_all_logs[log_idx])
					log_display.tooltip_text = full_text
				_maybe_clear_bracket_hover_for_line(log_idx)
		else:
			if _hovered_line_idx != -1:
				_hovered_line_idx = -1
				log_display.tooltip_text = ""
			_maybe_clear_bracket_hover_for_line(-1)

	# Drag-to-select: update range while left mouse is held.
	if (
		event is InputEventMouseMotion
		and _is_dragging_selection
		and (event.button_mask & MOUSE_BUTTON_MASK_LEFT)
	):
		_drag_moved = true
		var current_line := _get_line_at_mouse_pos(event.position)
		if current_line >= 0 and current_line < _displayed_line_map.size():
			_apply_drag_range(current_line)
			accept_event()


## Updates the selection for a drag whose pointer now sits over
## current_display_line. Extracted from the gui_input handler so tests can
## drive drag updates without synthesizing layout-dependent mouse events.
func _apply_drag_range(current_display_line: int) -> void:
	var range_start := mini(_drag_anchor_display_line, current_display_line)
	var range_end := maxi(_drag_anchor_display_line, current_display_line)
	var map_size := _displayed_line_map.size()
	range_start = clampi(range_start, 0, map_size - 1)
	range_end = clampi(range_end, 0, map_size - 1)

	# Skip if the range hasn't changed.
	if range_start == _drag_last_range.x and range_end == _drag_last_range.y:
		return

	# Capture the previous range BEFORE overwriting _drag_last_range
	# so the diff below can be computed against what was actually
	# in the selection dict on the previous motion event.
	var prev_start := _drag_last_range.x
	var prev_end := _drag_last_range.y
	_drag_last_range = Vector2i(range_start, range_end)

	# Diff against the previous drag range so per-motion dict work
	# scales with how much the range moved, not the full range.
	# A long drag at 60Hz on the 10,000-line cap was hitting
	# ~600k dict ops/sec; the previous range was reinserted
	# verbatim on every motion event.
	if prev_start < 0 or prev_end < 0:
		# First motion of this drag: insert the full range.
		# (clear() is the only correct setup for non-additive.)
		if not _drag_is_additive:
			_selected_log_indices.clear()
		for dl in range(range_start, range_end + 1):
			_selected_log_indices[_displayed_line_map[dl]] = true
	else:
		# Subsequent motion: erase what left the range (non-additive
		# only — additive drags accumulate and never shrink the
		# selection), then insert only the new slice(s).
		if not _drag_is_additive:
			if prev_start < range_start:
				for dl in range(prev_start, min(prev_end + 1, range_start)):
					_selected_log_indices.erase(_displayed_line_map[dl])
			if prev_end > range_end:
				for dl in range(max(prev_start, range_end + 1), prev_end + 1):
					_selected_log_indices.erase(_displayed_line_map[dl])
		if range_start < prev_start:
			for dl in range(range_start, min(prev_start, range_end + 1)):
				_selected_log_indices[_displayed_line_map[dl]] = true
		if range_end > prev_end:
			for dl in range(max(range_start, prev_end + 1), range_end + 1):
				_selected_log_indices[_displayed_line_map[dl]] = true

	_update_selection_info()
	_redraw_selection_overlay()


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

	# Binary search for the last paragraph whose offset is <= content_y.
	# Paragraph offsets are monotonically non-decreasing, so this matches
	# the previous linear scan from the end but is O(log n) per mouse move
	# instead of O(n) (matters at the 10,000 log line limit).
	var count := log_display.get_paragraph_count()
	var lo := 0
	var hi := count - 1
	var result := -1
	while lo <= hi:
		var mid := (lo + hi) / 2
		if content_y >= log_display.get_paragraph_offset(mid):
			result = mid
			lo = mid + 1
		else:
			hi = mid - 1
	return result


## Parses a caller meta URL ("<path>:<line>") into {"path", "line"}.
## Supports res://, Windows drive paths (C:/...), and relative/Unix paths.
## Returns an empty Dictionary when unparseable.
static func parse_caller_meta(meta_str: String) -> Dictionary:
	var parts := meta_str.split(":")
	if parts.size() >= 2 and parts[-1].is_valid_int():
		return {
			"path": ":".join(parts.slice(0, -1)),
			"line": parts[-1].to_int(),
		}
	return {}


## Parses a bracket-hover meta URL ("brk:<log>:<char>") into
## Vector2i(log_index, char_index). Returns Vector2i(-1, -1) when malformed.
## The strict 3-segment shape keeps it disjoint from caller metas
## ("<path>:<line>", which may contain ":" inside the path) and filter metas.
static func parse_bracket_meta(meta_str: String) -> Vector2i:
	var parts := meta_str.split(":")
	if (
		parts.size() == 3
		and parts[0] == "brk"
		and parts[1].is_valid_int()
		and parts[2].is_valid_int()
	):
		return Vector2i(int(parts[1]), int(parts[2]))
	return Vector2i(-1, -1)


func _on_log_meta_clicked(meta: Variant) -> void:
	if meta is String:
		var meta_str: String = meta

		if meta_str.begins_with("filter:"):
			_solo_category(meta_str.trim_prefix("filter:"))
			return

		# Bracket-hover links carry no click action; bail out before caller
		# parsing so "brk:<n>:<n>" can never be mistaken for a path:line.
		if parse_bracket_meta(meta_str).x >= 0:
			return

		var parsed := parse_caller_meta(meta_str)
		if not parsed.is_empty():
			var file_path: String = parsed.get("path", "")
			var line_num: int = parsed.get("line", 0)

			if FileAccess.file_exists(file_path):
				var res := load(file_path)
				if res is Script:
					# EditorInterface has no functional edit_script outside the
					# editor; the guard keeps the click path testable headless
					if Engine.is_editor_hint():
						EditorInterface.edit_script(res, line_num)


## meta_hover_started on one of the [url]-wrapped message brackets: resolve
## the matching counterpart and light both glyphs up via a display rebuild.
## Unmatched brackets (no entry in match_brackets) are ignored.
func _on_bracket_hover_started(meta: Variant) -> void:
	if not (meta is String):
		return
	var target := parse_bracket_meta(meta)
	if target.x < 0 or target.x >= _all_logs.size():
		return
	var matches := _get_bracket_matches(target.x)
	var mate: int = matches.get(target.y, -1)
	if mate == -1:
		return
	_bracket_hover = {"meta": meta, "log": target.x, "pair": [target.y, mate]}
	_schedule_display_rebuild()


## Clears the highlight when the bracket just left matches the active one.
## Exact-meta comparison keeps ordering safe: if a new hover starts before
## the old hover's ended event arrives, the old event cannot clear it.
func _on_bracket_hover_ended(meta: Variant) -> void:
	if _bracket_hover.is_empty() or not (meta is String):
		return
	if _bracket_hover.get("meta", "") != meta:
		return
	_bracket_hover.clear()
	_schedule_display_rebuild()


## Safety net for cases where meta_hover_ended may not fire (e.g. content
## scrolling beneath a stationary cursor): drop the bracket highlight once
## the pointer sits over a different log line than the hovered pair.
func _maybe_clear_bracket_hover_for_line(log_idx: int) -> void:
	if _bracket_hover.is_empty() or _bracket_hover.get("log", -1) == log_idx:
		return
	_bracket_hover.clear()
	_schedule_display_rebuild()


## Returns the bracket-pair map for a log, computing and caching it inside
## log_data on first use ("_bracket_matches", mirroring "_log_tags").
## Messages never change once logged, so the cache needs no invalidation.
func _get_bracket_matches(log_index: int) -> Dictionary[int, int]:
	var log_data: Dictionary = _all_logs[log_index]
	if not log_data.has("_bracket_matches"):
		log_data["_bracket_matches"] = (DLoggerPanelFormat.match_brackets(
			log_data.get("message", "")
		))
	return log_data["_bracket_matches"]


## Re-reads the bracket-highlight opacity from EditorSettings. A stand-in
## `es` can be injected for tests; without one (and inside the editor) the
## real EditorSettings are used. Returns true when the effective value
## changed, so callers can decide whether a display rebuild is needed.
func _refresh_bracket_highlight_setting(es: Object = null) -> bool:
	var setting := DLoggerConstants.EDITOR_SETTING_PANEL_BRACKET_HIGHLIGHT
	var value: Variant = null
	if es != null:
		if es.has_setting(setting):
			value = es.get_setting(setting)
	elif Engine.is_editor_hint():
		var editor_es := EditorInterface.get_editor_settings()
		if editor_es.has_setting(setting):
			value = editor_es.get_setting(setting)
	if value == null:
		return false
	var opacity := clampi(int(value), 0, 100)
	if opacity == _bracket_highlight_opacity:
		return false
	_bracket_highlight_opacity = opacity
	return true


## Live-updates the highlight while the user drags the opacity slider in
## Editor Settings; only rebuilds when a pair is currently lit.
func _on_bracket_highlight_setting_changed() -> void:
	if not _refresh_bracket_highlight_setting():
		return
	if not _bracket_hover.is_empty():
		_schedule_display_rebuild()


func _toggle_log_selection(log_index: int) -> void:
	if _selected_log_indices.has(log_index):
		_selected_log_indices.erase(log_index)
	else:
		_selected_log_indices[log_index] = true
	_update_selection_info()
	_redraw_selection_overlay()


## Creates the overlay that visualizes row selection on top of log_display.
## Selection never touches the RichTextLabel document itself, so selecting
## costs O(selected) per frame instead of an O(n) document rebuild.
func _setup_selection_overlay() -> void:
	_selection_overlay = Control.new()
	_selection_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Scrolled-off highlight rows must not paint over neighbouring controls.
	_selection_overlay.clip_contents = true
	_selection_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_selection_overlay.draw.connect(_draw_selection_overlay)
	log_display.add_child(_selection_overlay)
	var v_scroll := log_display.get_v_scroll_bar()
	if v_scroll:
		v_scroll.value_changed.connect(_on_log_scroll_changed)
	# Paragraph offsets also shift when the control reflows without any
	# scroll change (window resize, font size, word wrap).
	log_display.resized.connect(_redraw_selection_overlay.bind(true))


## Scrollbar value_changed forwards a float value; route it through this
## adapter so the overlay redraw keeps its bool `deferred` signature.
func _on_log_scroll_changed(_value: float) -> void:
	_redraw_selection_overlay()


func _redraw_selection_overlay(deferred: bool = false) -> void:
	if _selection_overlay == null:
		return
	if deferred:
		# Layout settles one frame later; redraw then so paragraph
		# offsets and heights read from a settled document.
		_selection_overlay.queue_redraw.call_deferred()
	else:
		_selection_overlay.queue_redraw()


func _draw_selection_overlay() -> void:
	if _selected_log_indices.is_empty() or _selection_overlay == null:
		return
	var para_count := log_display.get_paragraph_count()
	if para_count <= 0:
		return
	var v_scroll := log_display.get_v_scroll_bar()
	var scroll_y := v_scroll.value if v_scroll else 0.0
	var style := log_display.get_theme_stylebox(&"normal")
	var top_padding := style.content_margin_top if style else 0.0
	var width := maxf(_selection_overlay.size.x, 1.0)
	for log_idx: int in _selected_log_indices:
		var para: int = _log_to_display_map.get(log_idx, -1)
		if para < 0 or para >= para_count:
			continue
		var y_top := float(log_display.get_paragraph_offset(para))
		var y_bottom := (
			float(log_display.get_paragraph_offset(para + 1))
			if para + 1 < para_count
			else float(log_display.get_content_height())
		)
		var height := y_bottom - y_top
		# Layout may lag a rebuild by one frame; skip degenerate rects
		# rather than drawing garbage (the deferred redraw fixes it up).
		if height <= 0.0:
			continue
		_selection_overlay.draw_rect(
			Rect2(0.0, top_padding + y_top - scroll_y, width, height),
			SELECTION_HIGHLIGHT_COLOR
		)


## Rebuilds the log-index -> display-paragraph inverse of
## _displayed_line_map used by the selection overlay.
func _refresh_selection_map() -> void:
	_log_to_display_map.clear()
	for dl in range(_displayed_line_map.size()):
		_log_to_display_map[_displayed_line_map[dl]] = dl


func _update_selection_info() -> void:
	var count := _selected_log_indices.size()
	if count > 0:
		copy_button.tooltip_text = (
			"Copy Selected (%d) (Ctrl+C)\nEsc: Clear" % count
		)
	else:
		copy_button.tooltip_text = ("Copy Logs (Ctrl+C)")
	_refresh_stats_label()


func _append_formatted_log(log_data: Dictionary, log_index: int = -1) -> void:
	if log_display:
		# Selection is NOT baked into the document (see _setup_selection_
		# overlay): the is_selected flag stays supported by _format_log for
		# callers/tests that need it, but the live display always renders
		# unselected text and lets the overlay highlight rows.
		var bbcode_msg := _format_log(log_data, false, log_index)
		log_display.append_text(bbcode_msg + "\n")
		if _is_auto_scrolling:
			call_deferred("_scroll_to_bottom")


func _format_log_plain(log_data: Dictionary) -> String:
	return DLoggerPanelFormat.format_log_plain(log_data)


func _format_log(
	log_data: Dictionary, is_selected: bool = false, log_index: int = -1
) -> String:
	var bracket_hover: Array = []
	if log_index >= 0 and _bracket_hover.get("log", -1) == log_index:
		bracket_hover = _bracket_hover.get("pair", [])
	return DLoggerPanelFormat.format_log(
		log_data,
		_search,
		relative_checkbox.button_pressed,
		_get_max_log_time(),
		is_selected,
		log_index,
		bracket_hover,
		DLoggerPanelFormat.bracket_hover_bg(_bracket_highlight_opacity)
	)


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
	if not _search.matches(
		log_data.get("message", ""),
		log_data.get("category", ""),
		log_data.get("prefix", "")
	):
		return false

	return true


func _apply_font_size() -> void:
	_log_font_size = clampi(_log_font_size, MIN_FONT_SIZE, MAX_FONT_SIZE)
	log_display.add_theme_font_size_override(
		&"normal_font_size", _log_font_size
	)
	log_display.add_theme_font_size_override(&"bold_font_size", _log_font_size)
	# Reflow shifts paragraph offsets; redraw once layout has settled.
	_redraw_selection_overlay(true)
	if Engine.is_editor_hint():
		var es := EditorInterface.get_editor_settings()
		es.set_setting(EDITOR_SETTING_FONT_SIZE, _log_font_size)


func _change_font_size(delta: int) -> void:
	var new_size := clampi(_log_font_size + delta, MIN_FONT_SIZE, MAX_FONT_SIZE)
	if new_size != _log_font_size:
		_log_font_size = new_size
		_apply_font_size()


func _refresh_stats_label() -> void:
	var total_displayed := _displayed_line_map.size()
	var total_stored := _all_logs.size()
	var parts: Array[String] = []
	for level: String in ["DEBUG", "INFO", "WARN", "ERROR"]:
		parts.append("%s:%d" % [level, _stats_level_counts.get(level, 0)])
	var sel_count := _selected_log_indices.size()
	if sel_count > 0:
		stats_label.text = (
			"%s | (%d) %d / %d"
			% ["  ".join(parts), sel_count, total_displayed, total_stored]
		)
	else:
		stats_label.text = (
			"%s | %d / %d" % ["  ".join(parts), total_displayed, total_stored]
		)


func _rebuild_log_display() -> void:
	log_display.clear()
	_displayed_line_map.clear()
	for level: String in _stats_level_counts:
		_stats_level_counts[level] = 0
	for i in range(_all_logs.size()):
		var log_data: Dictionary = _all_logs[i]
		if _should_display_log(log_data):
			_displayed_line_map.append(i)
			var level: String = log_data.get("level", "DEBUG")
			_stats_level_counts[level] = _stats_level_counts.get(level, 0) + 1
			_append_formatted_log(log_data, i)
	_refresh_selection_map()
	_refresh_stats_label()
	_redraw_selection_overlay(true)
	if _is_auto_scrolling:
		call_deferred("_scroll_to_bottom")


## Rebuilds the log display while preserving the current scroll position.
## Call this instead of _rebuild_log_display() when the user has actively
## positioned the viewport (e.g. after a selection change).
## When auto-scroll is enabled, preservation is skipped so the view stays
## at the bottom.
func _rebuild_log_display_preserve_scroll() -> void:
	if _is_auto_scrolling:
		_rebuild_log_display()
		return

	var v_scroll := log_display.get_v_scroll_bar()
	var saved_scroll: float = v_scroll.value if v_scroll else 0.0
	log_display.scroll_following = false
	_rebuild_log_display()
	if v_scroll:
		# Defer scroll restoration so the layout has settled and the
		# scroll bar's max_value reflects the new content height.
		# Without this, the first selection can jump the viewport.
		v_scroll.call_deferred("set_value", saved_scroll)


## Schedules a display rebuild at the end of the current frame. Multiple
## calls within one frame collapse into a single rebuild, so rapid log
## stacking doesn't rebuild the whole display per log.
func _schedule_display_rebuild() -> void:
	if _rebuild_pending:
		return
	_rebuild_pending = true
	call_deferred("_flush_display_rebuild")


func _flush_display_rebuild() -> void:
	_rebuild_pending = false
	_rebuild_log_display_preserve_scroll()


func _scroll_to_bottom() -> void:
	var v_scroll := log_display.get_v_scroll_bar()
	if v_scroll and v_scroll.max_value > 0:
		v_scroll.value = v_scroll.max_value


func _update_auto_scroll_from_scrollbar() -> void:
	var v_scroll := log_display.get_v_scroll_bar()
	if not v_scroll:
		return
	# Scrollbar value clamps to (max_value - page), so the true bottom is
	# max_value - page, not max_value itself. Comparing against max_value
	# would never re-engage auto-scroll once the viewport has any height.
	var bottom: float = maxf(0.0, v_scroll.max_value - v_scroll.page)
	_is_auto_scrolling = v_scroll.value >= bottom - 0.5
	log_display.scroll_following = _is_auto_scrolling


func _on_word_wrap_toggled(button_pressed: bool) -> void:
	log_display.autowrap_mode = (
		TextServer.AUTOWRAP_WORD_SMART
		if button_pressed
		else TextServer.AUTOWRAP_OFF
	)
	# Wrapping changes paragraph heights without a document rebuild.
	_redraw_selection_overlay(true)


func _on_regex_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_search.compile()
	else:
		_search.regex = null
	_rebuild_log_display()


func _on_relative_toggled(_button_pressed: bool) -> void:
	_rebuild_log_display()


func _on_case_sensitive_toggled(button_pressed: bool) -> void:
	_search.case_sensitive = button_pressed
	if regex_checkbox.button_pressed:
		_search.compile()
	_rebuild_log_display()


func _on_search_text_changed(new_text: String) -> void:
	_search.query = new_text
	if regex_checkbox.button_pressed:
		_search.compile()

	# Debounce the display rebuild: rebuilding per keystroke clears and
	# reformats up to 10k lines. Empty queries rebuild immediately so
	# clearing feels instant; later keystrokes supersede any pending rebuild.
	_search_rebuild_token += 1
	if new_text.is_empty():
		_rebuild_log_display()
		return
	var token := _search_rebuild_token
	await get_tree().create_timer(SEARCH_DEBOUNCE_SECONDS).timeout
	if not is_instance_valid(self) or not is_inside_tree():
		return
	if token != _search_rebuild_token:
		return
	_rebuild_log_display()


func clear_logs() -> void:
	_all_logs.clear()
	_selected_log_indices.clear()
	_log_to_display_map.clear()
	_bracket_hover.clear()
	log_display.clear()
	_displayed_line_map.clear()
	_hovered_line_idx = -1
	log_display.tooltip_text = ""

	for child: Node in filter_container.get_children():
		child.queue_free()
	_active_filters.clear()

	# Reset search. set_pressed_no_signal avoids firing toggled here,
	# which would trigger redundant rebuilds of the just-cleared display;
	# _search.reset() already applied the equivalent state changes.
	_search.reset()
	search_line_edit.text = ""
	case_sensitive_checkbox.set_pressed_no_signal(false)
	regex_checkbox.set_pressed_no_signal(false)

	# Reset time filter to "All"
	_active_time_filter = -1.0
	time_option_button.select(0)

	# Restore saved level filter from EditorSettings
	var saved_level := 0
	if Engine.is_editor_hint():
		var es := EditorInterface.get_editor_settings()
		if es.has_setting(EDITOR_SETTING_LEVEL_FILTER):
			saved_level = es.get_setting(EDITOR_SETTING_LEVEL_FILTER)
	_active_level_filter = saved_level
	for i in level_option_button.item_count:
		if level_option_button.get_item_id(i) == saved_level:
			level_option_button.select(i)
			break

	for level: String in _stats_level_counts:
		_stats_level_counts[level] = 0
	_refresh_stats_label()
	_update_selection_info()
	_reset_auto_scroll()


func _reset_auto_scroll() -> void:
	_is_auto_scrolling = true
	log_display.scroll_following = true
	_scroll_to_bottom()
	call_deferred("_scroll_to_bottom")


func _on_clear_pressed() -> void:
	clear_logs()


func _on_copy_pressed() -> void:
	var formatted_logs: String = _get_formatted_logs()
	if formatted_logs.is_empty():
		return
	var copy_count := (
		_selected_log_indices.size()
		if not _selected_log_indices.is_empty()
		else _displayed_line_map.size()
	)
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
			# format_log_plain appends the stacked count (xN) when present
			output_text += DLoggerPanelFormat.format_log_plain(log_data) + "\n"
	return output_text


func _copy_to_clipboard(text: String, log_count: int = 0) -> void:
	DisplayServer.clipboard_set(text)

	var toast_msg := (
		"Copied %d log(s)" % log_count if log_count > 0 else "Copied"
	)
	_show_toast(toast_msg)

	var original_text := copy_button.text
	copy_button.text = "Copied!"
	await get_tree().create_timer(1.0).timeout
	if not is_instance_valid(self) or not is_inside_tree():
		return
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
	panel.position = Vector2((size.x - w) * 0.5, size.y - h - margin)

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
		if not is_instance_valid(self) or not is_inside_tree():
			return
		save_button.text = original_text
	else:
		push_error("Failed to save logs to %s" % file_path)


func _save_to_file(file_path: String, content: String) -> int:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(content)
	return OK
