class_name DLoggerPanelTest
extends GdUnitTestSuite

const _PANEL_SCENE = preload("res://addons/d_logger/panel/d_logger_panel.tscn")


# ------------- [Helper] -------------
func _instantiate_panel() -> Control:
	var panel: Control = _PANEL_SCENE.instantiate()
	add_child(panel)
	# Wait one frame for @onready to resolve
	await get_tree().process_frame
	return panel


func _make_log(
	message: String,
	level: String = "INFO",
	prefix: String = "D-Logger",
	category: String = ""
) -> Dictionary:
	# Compute tags the same way the panel does so _should_display_log works
	var tags: Array[String] = []
	if not category.is_empty():
		for tag in category.split("|"):
			var t := tag.strip_edges()
			if not t.is_empty():
				tags.append(t)
	if tags.is_empty() and not prefix.is_empty() and prefix != "D-Logger":
		tags.append(prefix)
	if tags.is_empty():
		tags.append("Default")
	return {
		"message": message,
		"level": level,
		"prefix": prefix,
		"category": category,
		"time": 1.0,
		"frame": 100,
		"caller_info": {},
		"context_str": "",
		"_log_tags": tags,
	}


func _populate_logs(panel: Control, count: int) -> void:
	for i in range(count):
		panel._all_logs.append(_make_log("msg_%d" % i))
		panel._displayed_line_map.append(i)
	panel._rebuild_log_display()


# ------------- [Constructor] -------------
func test_init() -> void:
	var panel := _PANEL_SCENE.instantiate()
	assert_object(panel).is_not_null()
	panel.free()


# ------------- [Toggle Selection] -------------
func test_toggle_log_selection_adds_index() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)

	panel._toggle_log_selection(2)

	assert_bool(panel._selected_log_indices.has(2)).is_true()
	assert_int(panel._selected_log_indices.size()).is_equal(1)
	panel.free()


func test_toggle_log_selection_removes_index() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)

	panel._toggle_log_selection(2)
	panel._toggle_log_selection(2)

	assert_bool(panel._selected_log_indices.has(2)).is_false()
	assert_int(panel._selected_log_indices.size()).is_equal(0)
	panel.free()


func test_toggle_log_selection_multiple_indices() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 10)

	panel._toggle_log_selection(0)
	panel._toggle_log_selection(3)
	panel._toggle_log_selection(7)

	assert_int(panel._selected_log_indices.size()).is_equal(3)
	assert_bool(panel._selected_log_indices.has(0)).is_true()
	assert_bool(panel._selected_log_indices.has(3)).is_true()
	assert_bool(panel._selected_log_indices.has(7)).is_true()
	panel.free()


func test_toggle_log_selection_does_not_affect_other_indices() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)

	panel._toggle_log_selection(1)
	panel._toggle_log_selection(2)

	panel._toggle_log_selection(1)

	assert_bool(panel._selected_log_indices.has(1)).is_false()
	assert_bool(panel._selected_log_indices.has(2)).is_true()
	assert_int(panel._selected_log_indices.size()).is_equal(1)
	panel.free()


# ------------- [Update Selection Info] -------------
func test_update_selection_info_empty() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)

	panel._selected_log_indices.clear()
	panel._update_selection_info()

	assert_str(panel.copy_button.tooltip_text).is_equal("Copy Logs (Ctrl+C)")
	panel.free()


func test_update_selection_info_with_selection() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)

	panel._selected_log_indices[0] = true
	panel._selected_log_indices[2] = true
	panel._update_selection_info()

	assert_str(panel.copy_button.tooltip_text).contains("Copy Selected (2)")
	panel.free()


func test_update_selection_info_after_clear() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)

	panel._selected_log_indices[0] = true
	panel._update_selection_info()
	assert_str(panel.copy_button.tooltip_text).contains("1")

	panel._selected_log_indices.clear()
	panel._update_selection_info()
	assert_str(panel.copy_button.tooltip_text).is_equal("Copy Logs (Ctrl+C)")
	panel.free()


# ------------- [Get Formatted Logs] -------------
func test_get_formatted_logs_no_selection() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)

	var result: String = panel._get_formatted_logs()

	assert_str(result).contains("msg_0")
	assert_str(result).contains("msg_1")
	assert_str(result).contains("msg_2")
	panel.free()


func test_get_formatted_logs_with_selection() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)

	panel._selected_log_indices[1] = true
	panel._selected_log_indices[3] = true

	var result: String = panel._get_formatted_logs()

	assert_str(result).not_contains("msg_0")
	assert_str(result).contains("msg_1")
	assert_str(result).not_contains("msg_2")
	assert_str(result).contains("msg_3")
	assert_str(result).not_contains("msg_4")
	panel.free()


func test_get_formatted_logs_empty_selection_is_like_no_selection() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)

	panel._selected_log_indices.clear()

	var result: String = panel._get_formatted_logs()

	assert_str(result).contains("msg_0")
	assert_str(result).contains("msg_1")
	assert_str(result).contains("msg_2")
	panel.free()


func test_get_formatted_logs_respects_level_filter() -> void:
	var panel := await _instantiate_panel()
	panel._all_logs.append(_make_log("debug_msg", "DEBUG"))
	panel._all_logs.append(_make_log("info_msg", "INFO"))
	panel._all_logs.append(_make_log("warn_msg", "WARN"))
	panel._all_logs.append(_make_log("error_msg", "ERROR"))
	for i in range(4):
		panel._displayed_line_map.append(i)
	panel._rebuild_log_display()

	# Filter to WARN+ only
	panel._active_level_filter = 2
	panel._rebuild_log_display()

	var result: String = panel._get_formatted_logs()

	assert_str(result).not_contains("debug_msg")
	assert_str(result).not_contains("info_msg")
	assert_str(result).contains("warn_msg")
	assert_str(result).contains("error_msg")
	panel.free()


func test_get_formatted_logs_respects_search_query() -> void:
	var panel := await _instantiate_panel()
	panel._all_logs.append(_make_log("hello world"))
	panel._all_logs.append(_make_log("foo bar"))
	panel._all_logs.append(_make_log("hello again"))
	for i in range(3):
		panel._displayed_line_map.append(i)
	panel._rebuild_log_display()

	panel._search_query = "hello"
	panel._rebuild_log_display()

	var result: String = panel._get_formatted_logs()

	assert_str(result).contains("hello world")
	assert_str(result).not_contains("foo bar")
	assert_str(result).contains("hello again")
	panel.free()


func test_get_formatted_logs_with_selection_and_search() -> void:
	var panel := await _instantiate_panel()
	panel._all_logs.append(_make_log("hello one"))
	panel._all_logs.append(_make_log("hello two"))
	panel._all_logs.append(_make_log("world three"))
	for i in range(3):
		panel._displayed_line_map.append(i)

	panel._search_query = "hello"
	panel._rebuild_log_display()

	# Select only the first displayed line (log index 0)
	panel._selected_log_indices[0] = true

	var result: String = panel._get_formatted_logs()

	assert_str(result).contains("hello one")
	assert_str(result).not_contains("hello two")
	assert_str(result).not_contains("world three")
	panel.free()


# ------------- [Should Display Log] -------------
func test_should_display_log_category_active() -> void:
	var panel := await _instantiate_panel()
	panel._active_filters["System"] = true

	var log_data: Dictionary = _make_log("test", "INFO", "D-Logger", "System")
	assert_bool(panel._should_display_log(log_data)).is_true()
	panel.free()


func test_should_display_log_category_inactive() -> void:
	var panel := await _instantiate_panel()
	panel._active_filters["System"] = false

	var log_data: Dictionary = _make_log("test", "INFO", "D-Logger", "System")
	assert_bool(panel._should_display_log(log_data)).is_false()
	panel.free()


func test_should_display_log_no_category_uses_default() -> void:
	var panel := await _instantiate_panel()
	panel._active_filters["Default"] = true

	var log_data: Dictionary = _make_log("test", "INFO", "D-Logger", "")
	assert_bool(panel._should_display_log(log_data)).is_true()
	panel.free()


func test_should_display_log_level_filter() -> void:
	var panel := await _instantiate_panel()
	panel._active_level_filter = 2  # WARN+

	var debug_log: Dictionary = _make_log("d", "DEBUG")
	var info_log: Dictionary = _make_log("i", "INFO")
	var warn_log: Dictionary = _make_log("w", "WARN")
	var error_log: Dictionary = _make_log("e", "ERROR")

	assert_bool(panel._should_display_log(debug_log)).is_false()
	assert_bool(panel._should_display_log(info_log)).is_false()
	assert_bool(panel._should_display_log(warn_log)).is_true()
	assert_bool(panel._should_display_log(error_log)).is_true()
	panel.free()


func test_should_display_log_search_query() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "error"

	var match_msg: Dictionary = _make_log("something error occurred")
	var no_match: Dictionary = _make_log("all good")

	assert_bool(panel._should_display_log(match_msg)).is_true()
	assert_bool(panel._should_display_log(no_match)).is_false()
	panel.free()


func test_should_display_log_search_in_category() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "network"

	var match_cat: Dictionary = _make_log("msg", "INFO", "D-Logger", "Network")
	var no_match: Dictionary = _make_log("msg", "INFO", "D-Logger", "Gameplay")

	assert_bool(panel._should_display_log(match_cat)).is_true()
	assert_bool(panel._should_display_log(no_match)).is_false()
	panel.free()


# ------------- [Get Log Tags] -------------
func test_get_log_tags_with_category() -> void:
	var panel := await _instantiate_panel()
	var log_data: Dictionary = _make_log("test", "INFO", "D-Logger", "Network")
	var tags: Array = panel._get_log_tags(log_data)
	assert_array(tags).contains_exactly("Network")
	panel.free()


func test_get_log_tags_with_multiple_tags() -> void:
	var panel := await _instantiate_panel()
	var log_data: Dictionary = _make_log("test", "INFO", "D-Logger", "AI|Combat")
	var tags: Array = panel._get_log_tags(log_data)
	assert_array(tags).contains_exactly_in_any_order("AI", "Combat")
	panel.free()


func test_get_log_tags_no_category_uses_prefix() -> void:
	var panel := await _instantiate_panel()
	var log_data: Dictionary = _make_log("test", "INFO", "CUSTOM_PREFIX", "")
	var tags: Array = panel._get_log_tags(log_data)
	assert_array(tags).contains_exactly("CUSTOM_PREFIX")
	panel.free()


func test_get_log_tags_no_category_default_prefix() -> void:
	var panel := await _instantiate_panel()
	var log_data: Dictionary = _make_log("test", "INFO", "D-Logger", "")
	var tags: Array = panel._get_log_tags(log_data)
	assert_array(tags).contains_exactly("Default")
	panel.free()


# ------------- [Clear Logs] -------------
func test_clear_logs_resets_selection() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)

	panel._selected_log_indices[0] = true
	panel._selected_log_indices[2] = true

	panel.clear_logs()

	assert_int(panel._selected_log_indices.size()).is_equal(0)
	assert_int(panel._all_logs.size()).is_equal(0)
	panel.free()


func test_clear_logs_resets_filters() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)

	panel._active_filters["System"] = false
	panel._search_query = "test"

	panel.clear_logs()

	assert_bool(panel._active_filters.is_empty()).is_true()
	assert_str(panel._search_query).is_equal("")
	panel.free()


# ------------- [Rebuild Log Display] -------------
func test_rebuild_log_display_clears_and_rebuilds() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)

	var initial_count: int = panel.log_display.get_paragraph_count()

	# Add one more log
	panel._all_logs.append(_make_log("msg_3"))
	panel._displayed_line_map.append(3)
	panel._rebuild_log_display()

	var after_count: int = panel.log_display.get_paragraph_count()
	assert_int(after_count).is_greater(initial_count)
	panel.free()


func test_rebuild_log_display_applies_filters() -> void:
	var panel := await _instantiate_panel()
	panel._all_logs.append(_make_log("debug_msg", "DEBUG"))
	panel._all_logs.append(_make_log("info_msg", "INFO"))
	panel._all_logs.append(_make_log("warn_msg", "WARN"))
	for i in range(3):
		panel._displayed_line_map.append(i)
	panel._rebuild_log_display()

	var all_count: int = panel.log_display.get_paragraph_count()

	# Set level filter to INFO+ — fewer logs displayed
	panel._active_level_filter = 1
	panel._rebuild_log_display()

	var filtered_count: int = panel.log_display.get_paragraph_count()
	assert_int(filtered_count).is_less(all_count)
	panel.free()


func test_rebuild_log_display_with_search() -> void:
	var panel := await _instantiate_panel()
	panel._all_logs.append(_make_log("hello world"))
	panel._all_logs.append(_make_log("foo bar"))
	panel._all_logs.append(_make_log("hello again"))
	for i in range(3):
		panel._displayed_line_map.append(i)
	panel._rebuild_log_display()

	var all_count: int = panel.log_display.get_paragraph_count()

	panel._search_query = "hello"
	panel._rebuild_log_display()

	var filtered_count: int = panel.log_display.get_paragraph_count()
	assert_int(filtered_count).is_less(all_count)
	panel.free()


# ------------- [Add Log] -------------
func test_add_log_increases_count() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("first"))

	assert_int(panel._all_logs.size()).is_equal(1)
	panel.free()


func test_add_log_stacking() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("same"))
	panel.add_log(_make_log("same"))
	panel.add_log(_make_log("same"))

	# Stacked logs should be merged into one
	assert_int(panel._all_logs.size()).is_equal(1)
	assert_int(panel._all_logs[0].get("count", 1)).is_equal(3)
	panel.free()


func test_add_log_no_stacking_different_message() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("msg_a"))
	panel.add_log(_make_log("msg_b"))

	assert_int(panel._all_logs.size()).is_equal(2)
	panel.free()


func test_add_log_no_stacking_different_level() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("same", "INFO"))
	panel.add_log(_make_log("same", "WARN"))

	assert_int(panel._all_logs.size()).is_equal(2)
	panel.free()


func test_add_log_creates_filter_button() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("test", "INFO", "D-Logger", "Network"))

	assert_bool(panel._active_filters.has("Network")).is_true()
	panel.free()


func test_add_log_does_not_duplicate_filter() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("test1", "INFO", "D-Logger", "Network"))
	panel.add_log(_make_log("test2", "INFO", "D-Logger", "Network"))

	var count: int = 0
	for child in panel.filter_container.get_children():
		if child is Button and child.text == "Network":
			count += 1
	assert_int(count).is_equal(1)
	panel.free()


# ------------- [Level Filter] -------------
func test_on_level_filter_pressed() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)

	panel._on_level_filter_pressed(2, panel._current_level_filter_button)

	assert_int(panel._active_level_filter).is_equal(2)
	panel.free()


# ------------- [Time Filter] -------------
func test_on_time_filter_pressed() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)

	panel._on_time_filter_pressed(30.0, panel._current_time_filter_button)

	assert_float(panel._active_time_filter).is_equal(30.0)
	panel.free()


# ------------- [Display Line Map] -------------
func test_display_line_map_tracks_visible_logs() -> void:
	var panel := await _instantiate_panel()
	panel._all_logs.append(_make_log("a", "INFO"))
	panel._all_logs.append(_make_log("b", "INFO"))
	panel._all_logs.append(_make_log("c", "INFO"))
	for i in range(3):
		panel._displayed_line_map.append(i)

	# Set level filter to WARN+ — nothing should display
	panel._active_level_filter = 2
	panel._rebuild_log_display()

	assert_int(panel._displayed_line_map.size()).is_equal(0)
	panel.free()


func test_display_line_map_after_add_log() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("first"))
	panel.add_log(_make_log("second"))

	assert_int(panel._displayed_line_map.size()).is_equal(2)
	panel.free()


# ------------- [_format_log - BBCode Formatting] -------------
func test_format_log_debug_has_gray_color() -> void:
	var panel := await _instantiate_panel()
	var log_data := _make_log("test", "DEBUG")
	var result: String = panel._format_log(log_data)
	assert_str(result).contains("[color=gray]")
	panel.free()


func test_format_log_info_has_bold_cyan() -> void:
	var panel := await _instantiate_panel()
	var log_data := _make_log("test", "INFO")
	var result: String = panel._format_log(log_data)
	assert_str(result).contains("[b][color=cyan]")
	assert_str(result).contains("[/color][/b]")
	panel.free()


func test_format_log_warn_has_bold_yellow() -> void:
	var panel := await _instantiate_panel()
	var log_data := _make_log("test", "WARN")
	var result: String = panel._format_log(log_data)
	assert_str(result).contains("[b][color=yellow]")
	panel.free()


func test_format_log_error_has_bold_red() -> void:
	var panel := await _instantiate_panel()
	var log_data := _make_log("test", "ERROR")
	var result: String = panel._format_log(log_data)
	assert_str(result).contains("[b][color=red]")
	panel.free()


func test_format_log_with_count() -> void:
	var panel := await _instantiate_panel()
	var log_data := _make_log("test", "INFO")
	log_data["count"] = 5
	var result: String = panel._format_log(log_data)
	assert_str(result).contains("(x5)")
	panel.free()


func test_format_log_selected_has_white_color() -> void:
	var panel := await _instantiate_panel()
	var log_data := _make_log("test", "DEBUG")
	var result: String = panel._format_log(log_data, true)
	assert_str(result).contains("[color=#ffffff]")
	panel.free()


# ------------- [_on_log_meta_clicked] -------------
func test_meta_click_select_toggles_selection() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)
	panel._ctrl_held = true
	panel._on_log_meta_clicked("select:2")
	assert_bool(panel._selected_log_indices.has(2)).is_true()
	panel._on_log_meta_clicked("select:2")
	assert_bool(panel._selected_log_indices.has(2)).is_false()
	panel.free()


func test_meta_click_filter_solos_category() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("msg1", "INFO", "D-Logger", "System"))
	panel.add_log(_make_log("msg2", "INFO", "D-Logger", "Network"))
	panel.add_log(_make_log("msg3", "INFO", "D-Logger", "AI"))
	panel._on_log_meta_clicked("filter:System")
	assert_bool(panel._active_filters["System"]).is_true()
	assert_bool(panel._active_filters["Network"]).is_false()
	assert_bool(panel._active_filters["AI"]).is_false()
	panel.free()


# ------------- [_solo_category] -------------
func test_solo_category_disables_others() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("msg1", "INFO", "D-Logger", "System"))
	panel.add_log(_make_log("msg2", "INFO", "D-Logger", "Network"))
	panel.add_log(_make_log("msg3", "INFO", "D-Logger", "AI"))
	panel._solo_category("Network")
	assert_bool(panel._active_filters["Network"]).is_true()
	assert_bool(panel._active_filters["System"]).is_false()
	assert_bool(panel._active_filters["AI"]).is_false()
	panel.free()


func test_solo_category_already_soloed_toggles_all() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("msg1", "INFO", "D-Logger", "Network"))
	panel.add_log(_make_log("msg2", "INFO", "D-Logger", "System"))
	panel.add_log(_make_log("msg3", "INFO", "D-Logger", "AI"))
	# Deactivate System and AI via their filter buttons
	for child in panel.filter_container.get_children():
		var btn := child as Button
		if btn and btn.text != "Network":
			btn.button_pressed = false
	# Now only Network is active
	panel._solo_category("Network")
	assert_bool(panel._active_filters["Network"]).is_true()
	assert_bool(panel._active_filters["System"]).is_true()
	assert_bool(panel._active_filters["AI"]).is_true()
	panel.free()


# ------------- [_unhandled_input - Keyboard Shortcuts] -------------
func test_unhandled_input_escape_clears_selection() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)
	panel._selected_log_indices[0] = true
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	panel._unhandled_input(event)
	assert_bool(panel._selected_log_indices.is_empty()).is_true()
	panel.free()


func test_unhandled_input_ctrl_f_focuses_search() -> void:
	var panel := await _instantiate_panel()
	panel.grab_focus()
	var event := InputEventKey.new()
	event.keycode = KEY_F
	event.ctrl_pressed = true
	event.pressed = true
	panel._unhandled_input(event)
	assert_bool(panel.search_line_edit.has_focus()).is_true()
	panel.free()


func test_unhandled_input_key_1_changes_level_filter() -> void:
	var panel := await _instantiate_panel()
	panel.grab_focus()
	panel._active_level_filter = 3
	var event := InputEventKey.new()
	event.keycode = KEY_1
	event.pressed = true
	panel._unhandled_input(event)
	assert_int(panel._active_level_filter).is_equal(0)
	panel.free()


func test_unhandled_input_key_2_changes_level_filter() -> void:
	var panel := await _instantiate_panel()
	panel.grab_focus()
	panel._active_level_filter = 0
	var event := InputEventKey.new()
	event.keycode = KEY_2
	event.pressed = true
	panel._unhandled_input(event)
	assert_int(panel._active_level_filter).is_equal(1)
	panel.free()


func test_unhandled_input_key_3_changes_level_filter() -> void:
	var panel := await _instantiate_panel()
	panel.grab_focus()
	panel._active_level_filter = 0
	var event := InputEventKey.new()
	event.keycode = KEY_3
	event.pressed = true
	panel._unhandled_input(event)
	assert_int(panel._active_level_filter).is_equal(2)
	panel.free()


func test_unhandled_input_key_4_changes_level_filter() -> void:
	var panel := await _instantiate_panel()
	panel.grab_focus()
	panel._active_level_filter = 0
	var event := InputEventKey.new()
	event.keycode = KEY_4
	event.pressed = true
	panel._unhandled_input(event)
	assert_int(panel._active_level_filter).is_equal(3)
	panel.free()


# ------------- [_input - Ctrl+C] -------------
func test_input_ctrl_c_triggers_copy() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)
	var event := InputEventKey.new()
	event.keycode = KEY_C
	event.ctrl_pressed = true
	event.pressed = true
	panel._input(event)
	# _on_copy_pressed runs synchronously up to clipboard_set + button text
	assert_str(panel.copy_button.text).is_equal("Copied!")
	panel.free()


func test_input_ctrl_c_ignored_when_search_focused() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)
	panel.search_line_edit.grab_focus()
	var original: String = panel.copy_button.text
	var event := InputEventKey.new()
	event.keycode = KEY_C
	event.ctrl_pressed = true
	event.pressed = true
	panel._input(event)
	assert_str(panel.copy_button.text).is_equal(original)
	panel.free()


# ------------- [_on_copy_pressed] -------------
func test_on_copy_pressed_with_selection() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)
	panel._selected_log_indices[0] = true
	panel._selected_log_indices[2] = true
	panel._on_copy_pressed()
	assert_str(panel.copy_button.text).is_equal("Copied!")
	panel.free()


func test_on_copy_pressed_without_selection() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)
	panel._on_copy_pressed()
	assert_str(panel.copy_button.text).is_equal("Copied!")
	panel.free()


func test_on_copy_pressed_empty_returns_early() -> void:
	var panel := await _instantiate_panel()
	panel._on_copy_pressed()
	# No logs — nothing to copy, button text should stay unchanged
	assert_str(panel.copy_button.text).is_not_equal("Copied!")
	panel.free()


# ------------- [_on_log_display_gui_input] -------------
func test_gui_input_click_outside_clears_selection() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)
	panel._selected_log_indices[2] = true
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = Vector2(0, 9999)
	panel._on_log_display_gui_input(event)
	assert_bool(panel._selected_log_indices.is_empty()).is_true()
	panel.free()


func test_gui_input_ctrl_click_outside_preserves_selection() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)
	panel._selected_log_indices[2] = true
	panel._selected_log_indices[3] = true
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.ctrl_pressed = true
	event.position = Vector2(0, 9999)
	panel._on_log_display_gui_input(event)
	# Ctrl+Click outside does NOT clear selection
	assert_bool(panel._selected_log_indices.has(2)).is_true()
	assert_bool(panel._selected_log_indices.has(3)).is_true()
	panel.free()


# ------------- [_rebuild_log_display_preserve_scroll] -------------
func test_rebuild_preserve_scroll() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 20)
	var v_scroll: ScrollBar = panel.log_display.get_v_scroll_bar()
	if v_scroll and v_scroll.max_value > 0.0:
		var expected := v_scroll.max_value * 0.3
		v_scroll.value = expected
		panel._rebuild_log_display_preserve_scroll()
		await get_tree().process_frame
		assert_float(v_scroll.value).is_equal(expected)
	panel.free()
