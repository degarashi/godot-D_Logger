class_name DLoggerPanelTest
extends GdUnitTestSuite

const _PANEL_SCENE = preload("res://addons/d_logger/panel/d_logger_panel.tscn")

var _temp_dir: String = ""


func before_test() -> void:
	_temp_dir = create_temp_dir("dlogger_panel_test")


func after_test() -> void:
	if not _temp_dir.is_empty():
		DirAccess.remove_absolute(_temp_dir)


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


func test_clear_logs_clears_displayed_line_map() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)

	panel.clear_logs()

	assert_int(panel._all_logs.size()).is_equal(0)
	assert_int(panel._displayed_line_map.size()).is_equal(0)
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


# ------------- [Regex Search] -------------
func test_should_display_log_regex_matches_message() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "err.*\\d+"
	panel._compile_search_regex()

	var match_msg: Dictionary = _make_log("error 404 occurred")
	var no_match: Dictionary = _make_log("all good")

	assert_bool(panel._should_display_log(match_msg)).is_true()
	assert_bool(panel._should_display_log(no_match)).is_false()
	panel.free()


func test_should_display_log_regex_matches_category() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "Net.*rk"
	panel._compile_search_regex()

	var match_cat: Dictionary = _make_log("msg", "INFO", "D-Logger", "Network")
	var no_match: Dictionary = _make_log("msg", "INFO", "D-Logger", "Gameplay")

	assert_bool(panel._should_display_log(match_cat)).is_true()
	assert_bool(panel._should_display_log(no_match)).is_false()
	panel.free()


func test_should_display_log_regex_case_insensitive_by_default() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "ERROR"
	panel._compile_search_regex()

	var match_msg: Dictionary = _make_log("error occurred")
	assert_bool(panel._should_display_log(match_msg)).is_true()
	panel.free()


func test_should_display_log_regex_case_sensitive() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "ERROR"
	panel._search_case_sensitive = true
	panel._compile_search_regex()

	var no_match: Dictionary = _make_log("error occurred")
	var match_exact: Dictionary = _make_log("ERROR occurred")
	assert_bool(panel._should_display_log(no_match)).is_false()
	assert_bool(panel._should_display_log(match_exact)).is_true()
	panel.free()


func test_should_display_log_regex_empty_query_shows_all() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = ""
	panel._compile_search_regex()

	var msg: Dictionary = _make_log("anything")
	assert_bool(panel._should_display_log(msg)).is_true()
	panel.free()


func test_should_display_log_regex_invalid_falls_back_to_plain_text() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "[invalid"
	panel._compile_search_regex()
	assert_bool(panel._search_regex == null).is_true()

	# Fallback to plain-text substring search — "[invalid" not in "test"
	var msg: Dictionary = _make_log("test")
	assert_bool(panel._should_display_log(msg)).is_false()
	panel.free()


func test_compile_search_regex_null_on_empty() -> void:
	var panel := await _instantiate_panel()
	panel._compile_search_regex()
	assert_bool(panel._search_regex == null).is_true()
	panel.free()


func test_compile_search_regex_null_on_invalid_pattern() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "("
	panel._compile_search_regex()
	assert_bool(panel._search_regex == null).is_true()
	panel.free()


func test_clear_logs_resets_regex_state() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "test"
	panel._compile_search_regex()
	assert_bool(panel._search_regex != null).is_true()

	panel.clear_logs()

	assert_bool(panel._search_regex == null).is_true()
	assert_bool(panel.regex_checkbox.button_pressed).is_false()
	panel.free()


func test_rebuild_log_display_with_regex() -> void:
	var panel := await _instantiate_panel()
	panel._all_logs.append(_make_log("hello world"))
	panel._all_logs.append(_make_log("say hello back"))
	panel._all_logs.append(_make_log("goodbye"))
	panel._rebuild_log_display()

	var all_count: int = panel._displayed_line_map.size()
	assert_int(all_count).is_equal(3)

	# "^hello" = regex anchor (start-of-string) — not a substring match
	panel._search_query = "^hello"
	panel._compile_search_regex()
	panel._rebuild_log_display()

	assert_int(panel._displayed_line_map.size()).is_equal(1)
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
	var log_data: Dictionary = _make_log(
		"test", "INFO", "D-Logger", "AI|Combat"
	)
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

	panel._on_level_option_selected(2)

	assert_int(panel._active_level_filter).is_equal(2)
	panel.free()


# ------------- [Time Filter] -------------
func test_on_time_filter_pressed() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)

	panel._on_time_option_selected(1)

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
	# The panel only handles Ctrl+C when focus is inside it
	panel.grab_focus()
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


# ------------- [drag-to-select clamping] -------------
func test_drag_select_basic_range() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 10)
	# Start drag at line 2
	panel._is_dragging_selection = true
	panel._drag_anchor_display_line = 2
	panel._drag_moved = false
	panel._drag_last_range = Vector2i(-1, -1)
	# Move to line 5
	var event := InputEventMouseMotion.new()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = Vector2(0, 5 * 20)  # Approximate line height
	panel._on_log_display_gui_input(event)
	# Should select lines 2-5
	assert_int(panel._selected_log_indices.size()).is_equal(4)
	assert_bool(panel._selected_log_indices.has(2)).is_true()
	assert_bool(panel._selected_log_indices.has(5)).is_true()
	panel._is_dragging_selection = false
	panel.free()


func test_drag_select_clamp_after_shrink() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 10)
	# Start drag at line 8 (near end)
	panel._is_dragging_selection = true
	panel._drag_anchor_display_line = 8
	panel._drag_moved = false
	panel._drag_last_range = Vector2i(-1, -1)
	# Shrink the map to 5 lines (simulating filter change)
	panel._displayed_line_map.resize(5)
	# Move to line 4
	var event := InputEventMouseMotion.new()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = Vector2(0, 4 * 20)
	panel._on_log_display_gui_input(event)
	# Clamp should prevent out-of-bounds: no index >= map_size should be selected
	for idx in panel._selected_log_indices:
		assert_int(idx).is_less(5)
	panel._is_dragging_selection = false
	panel.free()


func test_drag_select_clamp_anchor_out_of_range() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 10)
	# Start drag at line 2
	panel._is_dragging_selection = true
	panel._drag_anchor_display_line = 2
	panel._drag_moved = false
	panel._drag_last_range = Vector2i(-1, -1)
	# Shrink the map to 3 lines
	panel._displayed_line_map.resize(3)
	# Move to line 1
	var event := InputEventMouseMotion.new()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = Vector2(0, 1 * 20)
	panel._on_log_display_gui_input(event)
	# Clamp should prevent out-of-bounds: no index >= map_size should be selected
	for idx in panel._selected_log_indices:
		assert_int(idx).is_less(3)
	panel._is_dragging_selection = false
	panel.free()


func test_drag_select_skip_unchanged_range() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 10)
	# Start drag at line 3
	panel._is_dragging_selection = true
	panel._drag_anchor_display_line = 3
	panel._drag_moved = false
	panel._drag_last_range = Vector2i(-1, -1)
	# Move to line 5
	var event := InputEventMouseMotion.new()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = Vector2(0, 5 * 20)
	panel._on_log_display_gui_input(event)
	var first_count: int = panel._selected_log_indices.size()
	# Move again to same relative position (same range)
	panel._on_log_display_gui_input(event)
	# Should not add more selections (range unchanged)
	assert_int(panel._selected_log_indices.size()).is_equal(first_count)
	panel._is_dragging_selection = false
	panel.free()


func test_drag_select_reverse_direction() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 10)
	# Start drag at line 7
	panel._is_dragging_selection = true
	panel._drag_anchor_display_line = 7
	panel._drag_moved = false
	panel._drag_last_range = Vector2i(-1, -1)
	# Move backward to line 3
	var event := InputEventMouseMotion.new()
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.position = Vector2(0, 3 * 20)
	panel._on_log_display_gui_input(event)
	# Should select lines 3-7 (5 lines)
	assert_int(panel._selected_log_indices.size()).is_equal(5)
	assert_bool(panel._selected_log_indices.has(3)).is_true()
	assert_bool(panel._selected_log_indices.has(7)).is_true()
	panel._is_dragging_selection = false
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


# ------------- [_highlight_search_text] -------------
func test_highlight_search_text_wraps_matches() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "abc"
	var result: String = panel._highlight_search_text("xxabcyy")
	assert_str(result).contains("[bgcolor=yellow][color=black]abc[/color][/bgcolor]")
	panel.free()


func test_highlight_search_text_empty_query_unchanged() -> void:
	var panel := await _instantiate_panel()
	var result: String = panel._highlight_search_text("hello")
	assert_str(result).is_equal("hello")
	panel.free()


func test_highlight_search_text_multiple_matches() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "ab"
	var result: String = panel._highlight_search_text("ab ab ab")
	assert_int(result.count("[bgcolor=yellow]")).is_equal(3)
	panel.free()


func test_highlight_search_text_case_insensitive_by_default() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "ABC"
	var result: String = panel._highlight_search_text("xxabcxx")
	assert_str(result).contains("[color=black]abc[/color]")
	panel.free()


# ------------- [_format_log BBCode Escaping] -------------
func test_format_log_escapes_bbcode_in_message() -> void:
	var panel := await _instantiate_panel()
	var log := _make_log("[b]inject[/b]")
	var result: String = panel._format_log(log)
	assert_str(result).contains("[lb]b[rb]inject[lb]/b[rb]")
	assert_bool(result.contains("[b]inject[/b]")).is_false()
	panel.free()


func test_format_log_escapes_bbcode_with_search_highlight() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "inject"
	var log := _make_log("[b]inject[/b]")
	var result: String = panel._format_log(log)
	assert_str(result).contains(
		"[lb]b[rb][bgcolor=yellow][color=black]inject[/color][/bgcolor][lb]/b[rb]"
	)
	panel.free()


func test_highlight_search_text_case_sensitive() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "ABC"
	panel._search_case_sensitive = true
	var result: String = panel._highlight_search_text("xxabcxx")
	assert_str(result).is_equal("xxabcxx")
	panel.free()


func test_highlight_search_text_regex() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "a+b"
	panel._compile_search_regex()
	var result: String = panel._highlight_search_text("xaabz")
	assert_str(result).contains("[color=black]aab[/color]")
	panel.free()


# ------------- [_format_log_plain] -------------
func test_format_log_plain_has_no_bbcode() -> void:
	var panel := await _instantiate_panel()
	var result: String = panel._format_log_plain(_make_log("hello world"))
	assert_str(result).contains("hello world")
	assert_bool(result.contains("[color=")).is_false()
	assert_bool(result.contains("[b]")).is_false()
	panel.free()


func test_format_log_plain_with_count() -> void:
	var panel := await _instantiate_panel()
	var log_data := _make_log("dup")
	log_data["count"] = 4
	var result: String = panel._format_log_plain(log_data)
	assert_str(result).contains("(x4)")
	panel.free()


# ------------- [Relative Time] -------------
func test_format_log_relative_time() -> void:
	var panel := await _instantiate_panel()
	panel.relative_checkbox.button_pressed = true
	panel._all_logs.append(_make_log("first"))
	panel._all_logs.append(_make_log("second"))
	panel._all_logs.append(_make_log("third"))
	panel._all_logs[0]["time"] = 1.0
	panel._all_logs[1]["time"] = 2.0
	panel._all_logs[2]["time"] = 5.0
	var result: String = panel._format_log(panel._all_logs[0])
	assert_str(result).contains("-4.000s")
	panel.free()


func test_relative_toggle_rebuilds_display() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 2)
	var before: int = panel.log_display.get_paragraph_count()
	panel._on_relative_toggled(true)
	assert_int(panel.log_display.get_paragraph_count()).is_equal(before)
	panel.free()


# ------------- [_get_max_log_time] -------------
func test_get_max_log_time_empty() -> void:
	var panel := await _instantiate_panel()
	assert_float(panel._get_max_log_time()).is_equal(0.0)
	panel.free()


func test_get_max_log_time_returns_latest() -> void:
	var panel := await _instantiate_panel()
	panel._all_logs.append(_make_log("a"))
	panel._all_logs.append(_make_log("b"))
	panel._all_logs.append(_make_log("c"))
	panel._all_logs[2]["time"] = 42.0
	assert_float(panel._get_max_log_time()).is_equal(42.0)
	panel.free()


# ------------- [_get_log_level_value] -------------
func test_get_log_level_value_known_levels() -> void:
	var panel := await _instantiate_panel()
	assert_int(panel._get_log_level_value("DEBUG")).is_equal(0)
	assert_int(panel._get_log_level_value("INFO")).is_equal(1)
	assert_int(panel._get_log_level_value("WARN")).is_equal(2)
	assert_int(panel._get_log_level_value("ERROR")).is_equal(3)
	panel.free()


func test_get_log_level_value_unknown_defaults_to_debug() -> void:
	var panel := await _instantiate_panel()
	assert_int(panel._get_log_level_value("TRACE")).is_equal(0)
	panel.free()


# ------------- [_apply_level_filter] -------------
func test_apply_level_filter_selects_matching_item() -> void:
	var panel := await _instantiate_panel()
	panel._apply_level_filter(2)
	assert_int(panel._active_level_filter).is_equal(2)
	var selected_index: int = panel.level_option_button.selected
	assert_int(panel.level_option_button.get_item_id(selected_index)).is_equal(2)
	panel.free()


func test_apply_level_filter_unknown_level_is_noop() -> void:
	var panel := await _instantiate_panel()
	var before: int = panel._active_level_filter
	panel._apply_level_filter(99)
	assert_int(panel._active_level_filter).is_equal(before)
	panel.free()


# ------------- [_change_font_size / _apply_font_size] -------------
func test_change_font_size_increases() -> void:
	var panel := await _instantiate_panel()
	panel._change_font_size(2)
	assert_int(panel._log_font_size).is_equal(16)
	assert_int(panel.log_display.get_theme_font_size("normal_font_size")).is_equal(16)
	panel.free()


func test_change_font_size_clamps_at_max() -> void:
	var panel := await _instantiate_panel()
	panel._log_font_size = 31
	panel._change_font_size(2)
	assert_int(panel._log_font_size).is_equal(32)
	panel.free()


func test_change_font_size_clamps_at_min() -> void:
	var panel := await _instantiate_panel()
	panel._log_font_size = 9
	panel._change_font_size(-2)
	assert_int(panel._log_font_size).is_equal(8)
	panel.free()


func test_apply_font_size_clamps_out_of_range() -> void:
	var panel := await _instantiate_panel()
	panel._log_font_size = 100
	panel._apply_font_size()
	assert_int(panel._log_font_size).is_equal(32)
	panel.free()


# ------------- [_refresh_stats_label] -------------
func test_refresh_stats_label_shows_counts() -> void:
	var panel := await _instantiate_panel()
	panel._all_logs.append(_make_log("a"))
	panel._all_logs.append(_make_log("b"))
	panel._displayed_line_map.append(0)
	panel._displayed_line_map.append(1)
	panel._stats_level_counts["INFO"] = 2
	panel._refresh_stats_label()
	assert_str(panel.stats_label.text).contains("INFO:2")
	assert_str(panel.stats_label.text).contains("2 / 2")
	panel.free()


func test_refresh_stats_label_with_selection() -> void:
	var panel := await _instantiate_panel()
	panel._all_logs.append(_make_log("a"))
	panel._displayed_line_map.append(0)
	panel._stats_level_counts["INFO"] = 1
	panel._selected_log_indices[0] = true
	panel._refresh_stats_label()
	assert_str(panel.stats_label.text).contains("(1)")
	panel.free()


# ------------- [Filter Buttons] -------------
func test_add_filter_button_creates_toggle() -> void:
	var panel := await _instantiate_panel()
	panel._add_filter_button("System")
	var found: Button = null
	for child in panel.filter_container.get_children():
		var btn := child as Button
		if btn and btn.text == "System":
			found = btn
	assert_object(found).is_not_null()
	assert_bool(found.toggle_mode).is_true()
	assert_bool(found.button_pressed).is_true()
	assert_bool(panel._active_filters["System"]).is_true()
	panel.free()


func test_filter_toggle_off_updates_state_and_style() -> void:
	var panel := await _instantiate_panel()
	panel._add_filter_button("System")
	var btn: Button = panel.filter_container.get_child(0)
	panel._on_filter_toggled(false, "System", btn)
	assert_bool(panel._active_filters["System"]).is_false()
	assert_float(btn.modulate.a).is_equal(0.5)
	panel.free()


func test_filter_toggle_on_updates_state_and_style() -> void:
	var panel := await _instantiate_panel()
	panel._add_filter_button("System")
	var btn: Button = panel.filter_container.get_child(0)
	panel._on_filter_toggled(true, "System", btn)
	assert_bool(panel._active_filters["System"]).is_true()
	assert_float(btn.modulate.r).is_equal_approx(0.3, 0.001)
	assert_float(btn.modulate.g).is_equal_approx(0.8, 0.001)
	panel.free()


func test_update_button_style_active() -> void:
	var panel := await _instantiate_panel()
	var btn := Button.new()
	panel._update_button_style(btn, true)
	assert_float(btn.modulate.r).is_equal_approx(0.3, 0.001)
	assert_float(btn.modulate.g).is_equal_approx(0.8, 0.001)
	assert_float(btn.modulate.b).is_equal_approx(1.0, 0.001)
	btn.free()
	panel.free()


func test_update_button_style_inactive() -> void:
	var panel := await _instantiate_panel()
	var btn := Button.new()
	panel._update_button_style(btn, false)
	assert_float(btn.modulate.r).is_equal_approx(1.0, 0.001)
	assert_float(btn.modulate.g).is_equal_approx(1.0, 0.001)
	assert_float(btn.modulate.b).is_equal_approx(1.0, 0.001)
	assert_float(btn.modulate.a).is_equal_approx(0.5, 0.001)
	btn.free()
	panel.free()


func test_show_all_reactivates_all_filters() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("m1", "INFO", "P", "System"))
	panel.add_log(_make_log("m2", "INFO", "P", "Network"))
	for child in panel.filter_container.get_children():
		var btn := child as Button
		if btn and btn.text == "Network":
			btn.button_pressed = false
	assert_bool(panel._active_filters["Network"]).is_false()

	panel._on_show_all_pressed()

	for cat in panel._active_filters:
		assert_bool(panel._active_filters[cat]).is_true()
	for child in panel.filter_container.get_children():
		var btn := child as Button
		if btn:
			assert_bool(btn.button_pressed).is_true()
	panel.free()


func test_filter_gui_input_alt_click_solos() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("m1", "INFO", "P", "System"))
	panel.add_log(_make_log("m2", "INFO", "P", "Network"))
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.alt_pressed = true
	panel._on_filter_gui_input(event, "System")
	assert_bool(panel._active_filters["System"]).is_true()
	assert_bool(panel._active_filters["Network"]).is_false()
	panel.free()


func test_filter_gui_input_plain_click_ignored() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("m1", "INFO", "P", "System"))
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	panel._on_filter_gui_input(event, "System")
	assert_bool(panel._active_filters["System"]).is_true()
	panel.free()


# ------------- [Shortcuts] -------------
func test_create_shortcut_ctrl() -> void:
	var panel := await _instantiate_panel()
	var shortcut: Shortcut = panel._create_shortcut(KEY_L, true)
	var event := shortcut.events[0] as InputEventKey
	assert_int(event.keycode).is_equal(KEY_L)
	assert_bool(event.ctrl_pressed).is_true()
	panel.free()


func test_create_shortcut_shift() -> void:
	var panel := await _instantiate_panel()
	var shortcut: Shortcut = panel._create_shortcut(KEY_P, false, true)
	var event := shortcut.events[0] as InputEventKey
	assert_bool(event.shift_pressed).is_true()
	assert_bool(event.ctrl_pressed).is_false()
	panel.free()


func test_create_shortcut_alt_with_ctrl() -> void:
	var panel := await _instantiate_panel()
	var shortcut: Shortcut = panel._create_shortcut(KEY_S, true, false, true)
	var event := shortcut.events[0] as InputEventKey
	assert_int(event.keycode).is_equal(KEY_S)
	assert_bool(event.ctrl_pressed).is_true()
	assert_bool(event.alt_pressed).is_true()
	panel.free()


func test_setup_shortcuts_assigns_to_buttons() -> void:
	var panel := await _instantiate_panel()
	assert_object(panel.clear_button.shortcut).is_not_null()
	assert_object(panel.copy_button.shortcut).is_not_null()
	assert_object(panel.save_button.shortcut).is_not_null()
	assert_str(panel.save_button.tooltip_text).contains("Ctrl+Alt+S")
	panel.free()


# ------------- [_save_to_file] -------------
func test_save_to_file_writes_content() -> void:
	var panel := await _instantiate_panel()
	var path := _temp_dir.path_join("saved.txt")
	var result: int = panel._save_to_file(path, "line1\nline2")
	assert_int(result).is_equal(OK)
	var file := FileAccess.open(path, FileAccess.READ)
	assert_object(file).is_not_null()
	assert_str(file.get_as_text()).is_equal("line1\nline2")
	file.close()
	panel.free()


func test_save_to_file_missing_directory_returns_error() -> void:
	var panel := await _instantiate_panel()
	var result: int = panel._save_to_file(
		_temp_dir.path_join("no_dir").path_join("x.txt"), "x"
	)
	assert_int(result).is_not_equal(OK)
	panel.free()


# ------------- [_on_clear_pressed] -------------
func test_on_clear_pressed_clears_all() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)
	var before: int = panel.log_display.get_paragraph_count()
	panel._on_clear_pressed()
	assert_int(panel._all_logs.size()).is_equal(0)
	assert_int(panel.log_display.get_paragraph_count()).is_less(before)
	panel.free()


# ------------- [Auto Scroll] -------------
func test_reset_auto_scroll_enables_following() -> void:
	var panel := await _instantiate_panel()
	panel._is_auto_scrolling = false
	panel.log_display.scroll_following = false
	panel._reset_auto_scroll()
	assert_bool(panel._is_auto_scrolling).is_true()
	assert_bool(panel.log_display.scroll_following).is_true()
	panel.free()


func test_update_auto_scroll_from_scrollbar_at_bottom() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)
	var v_scroll: ScrollBar = panel.log_display.get_v_scroll_bar()
	if v_scroll and v_scroll.max_value > 0.0:
		panel._is_auto_scrolling = false
		v_scroll.value = v_scroll.max_value
		panel._update_auto_scroll_from_scrollbar()
		assert_bool(panel._is_auto_scrolling).is_true()
	panel.free()


func test_update_auto_scroll_from_scrollbar_above_bottom() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 5)
	var v_scroll: ScrollBar = panel.log_display.get_v_scroll_bar()
	if v_scroll and v_scroll.max_value > 0.0:
		panel._is_auto_scrolling = true
		v_scroll.value = maxf(0.0, v_scroll.max_value - 10.0)
		panel._update_auto_scroll_from_scrollbar()
		assert_bool(panel._is_auto_scrolling).is_false()
	panel.free()


# ------------- [_on_word_wrap_toggled] -------------
func test_word_wrap_on() -> void:
	var panel := await _instantiate_panel()
	panel._on_word_wrap_toggled(true)
	assert_int(panel.log_display.autowrap_mode).is_equal(TextServer.AUTOWRAP_WORD_SMART)
	panel.free()


func test_word_wrap_off() -> void:
	var panel := await _instantiate_panel()
	panel._on_word_wrap_toggled(false)
	assert_int(panel.log_display.autowrap_mode).is_equal(TextServer.AUTOWRAP_OFF)
	panel.free()


# ------------- [_on_visibility_changed] -------------
func test_visibility_changed_hidden_resets_right_drag() -> void:
	var panel := await _instantiate_panel()
	panel._is_right_dragging = true
	panel.visible = false
	assert_bool(panel._is_right_dragging).is_false()
	panel.free()


# ------------- [Toast] -------------
func test_make_toast_stylebox_rounded() -> void:
	var panel := await _instantiate_panel()
	var sb: StyleBoxFlat = panel._make_toast_stylebox()
	assert_int(sb.corner_radius_top_left).is_equal(6)
	assert_int(sb.corner_radius_bottom_right).is_equal(6)
	assert_float(sb.bg_color.a).is_equal_approx(0.92, 0.001)
	panel.free()


func test_show_toast_creates_panel_and_positions_it() -> void:
	var panel := await _instantiate_panel()
	panel._show_toast("hello")
	await get_tree().process_frame
	var toast: Panel = null
	for child in panel.get_children():
		if child is Panel:
			toast = child
	assert_object(toast).is_not_null()
	var label := toast.get_child(0) as Label
	assert_object(label).is_not_null()
	assert_str(label.text).is_equal("hello")
	var expected_pos := Vector2(
		(panel.size.x - 220.0) * 0.5, panel.size.y - 36.0 - 12.0
	)
	assert_float(toast.position.x).is_equal(expected_pos.x)
	# The slide-up tween has already started by the time the deferred
	# _animate_toast runs, so y animates between its start and start - 20.
	assert_float(toast.position.y).is_between(expected_pos.y - 20.0, expected_pos.y)
	panel.free()


# ------------- [_get_line_at_mouse_pos] -------------
func test_get_line_at_mouse_pos_empty_display_returns_minus_one() -> void:
	var panel := await _instantiate_panel()
	# A y above the first paragraph matches no line
	assert_int(panel._get_line_at_mouse_pos(Vector2(0, -1000))).is_equal(-1)
	panel.free()


func test_get_line_at_mouse_pos_matches_paragraph() -> void:
	var panel := await _instantiate_panel()
	_populate_logs(panel, 3)
	# Let the display lay out so paragraph offsets are computed
	await get_tree().process_frame
	var v_scroll: ScrollBar = panel.log_display.get_v_scroll_bar()
	if v_scroll:
		v_scroll.value = 0.0
	var style: StyleBox = panel.log_display.get_theme_stylebox(&"normal")
	var top_padding: float = style.content_margin_top if style else 0.0
	for i in range(panel.log_display.get_paragraph_count()):
		var y: float = panel.log_display.get_paragraph_offset(i) + top_padding + 1
		assert_int(panel._get_line_at_mouse_pos(Vector2(0, y))).is_equal(i)
	panel.free()


# ------------- [Scheduled Rebuild] -------------
func test_schedule_display_rebuild_coalesces() -> void:
	var panel := await _instantiate_panel()
	panel._all_logs.append(_make_log("a"))
	panel._schedule_display_rebuild()
	assert_bool(panel._rebuild_pending).is_true()
	panel._schedule_display_rebuild()
	assert_bool(panel._rebuild_pending).is_true()
	await get_tree().process_frame
	assert_bool(panel._rebuild_pending).is_false()
	assert_int(panel._displayed_line_map.size()).is_equal(1)
	panel.free()


func test_flush_display_rebuild_rebuilds_display() -> void:
	var panel := await _instantiate_panel()
	panel._all_logs.append(_make_log("a"))
	panel._all_logs.append(_make_log("b"))
	panel._rebuild_pending = true
	panel._flush_display_rebuild()
	assert_bool(panel._rebuild_pending).is_false()
	assert_int(panel._displayed_line_map.size()).is_equal(2)
	assert_int(panel.log_display.get_paragraph_count()).is_greater_equal(2)
	panel.free()


func test_add_log_stacking_schedules_rebuild() -> void:
	var panel := await _instantiate_panel()
	panel.add_log(_make_log("same"))
	panel.add_log(_make_log("same"))
	assert_bool(panel._rebuild_pending).is_true()
	await get_tree().process_frame
	assert_bool(panel._rebuild_pending).is_false()
	assert_int(panel._all_logs[0].get("count")).is_equal(2)
	panel.free()


# ------------- [_append_formatted_log] -------------
func test_append_formatted_log_appends_line() -> void:
	var panel := await _instantiate_panel()
	panel._append_formatted_log(_make_log("appended"))
	assert_int(panel.log_display.get_paragraph_count()).is_greater(0)
	panel.free()


func test_append_formatted_log_selected() -> void:
	var panel := await _instantiate_panel()
	panel._selected_log_indices[0] = true
	panel._append_formatted_log(_make_log("sel"), 0)
	assert_int(panel.log_display.get_paragraph_count()).is_greater(0)
	panel.free()


# ------------- [Option Button Setup] -------------
func test_time_option_button_presets() -> void:
	var panel := await _instantiate_panel()
	assert_int(panel.time_option_button.item_count).is_equal(4)
	# "All" is added with id -1 which Godot auto-assigns to the item index (0)
	assert_str(panel.time_option_button.get_item_text(0)).is_equal("All")
	assert_int(panel.time_option_button.get_item_id(1)).is_equal(30)
	assert_int(panel.time_option_button.get_item_id(2)).is_equal(60)
	assert_int(panel.time_option_button.get_item_id(3)).is_equal(300)
	panel.free()


func test_level_option_button_presets() -> void:
	var panel := await _instantiate_panel()
	assert_int(panel.level_option_button.item_count).is_equal(4)
	for i in range(4):
		assert_int(panel.level_option_button.get_item_id(i)).is_equal(i)
	panel.free()


# ------------- [Search UI Handlers] -------------
func test_search_text_changed_sets_query() -> void:
	var panel := await _instantiate_panel()
	panel._on_search_text_changed("abc")
	assert_str(panel._search_query).is_equal("abc")
	panel.free()


func test_regex_toggle_on_compiles_regex() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "^hello"
	panel._on_regex_toggled(true)
	assert_object(panel._search_regex).is_not_null()
	panel.free()


func test_regex_toggle_off_clears_regex() -> void:
	var panel := await _instantiate_panel()
	panel._search_query = "^hello"
	panel._compile_search_regex()
	assert_object(panel._search_regex).is_not_null()
	panel._on_regex_toggled(false)
	assert_object(panel._search_regex).is_null()
	panel.free()


func test_case_sensitive_toggle_updates_flag() -> void:
	var panel := await _instantiate_panel()
	panel._on_case_sensitive_toggled(true)
	assert_bool(panel._search_case_sensitive).is_true()
	panel.free()


# ------------- [Pause on Error Button Style] -------------
func test_update_pause_on_error_button_style_active() -> void:
	var panel := await _instantiate_panel()
	panel._update_pause_on_error_button_style(true)
	assert_float(panel.pause_on_error_button.modulate.r).is_equal_approx(1.0, 0.001)
	assert_float(panel.pause_on_error_button.modulate.g).is_equal_approx(0.4, 0.001)
	panel.free()


func test_update_pause_on_error_button_style_inactive() -> void:
	var panel := await _instantiate_panel()
	panel._update_pause_on_error_button_style(false)
	assert_float(panel.pause_on_error_button.modulate.a).is_equal(0.5)
	panel.free()


# ------------- [_on_save_pressed] -------------
func test_on_save_pressed_empty_returns_early() -> void:
	var panel := await _instantiate_panel()
	panel._on_save_pressed()
	assert_str(panel.save_button.text).is_not_equal("Saved!")
	panel.free()
