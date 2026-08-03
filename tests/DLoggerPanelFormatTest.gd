class_name DLoggerPanelFormatTest
extends GdUnitTestSuite


# ------------- [Helper] -------------
func _make_log(
	message: String,
	level: String = "INFO",
	prefix: String = "D-Logger",
	category: String = ""
) -> Dictionary:
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


# ------------- [get_log_tags] -------------
func test_get_log_tags_with_category() -> void:
	var tags: Array = DLoggerPanelFormat.get_log_tags(
		_make_log("x", "INFO", "D-Logger", "network")
	)
	assert_array(tags).contains_exactly(["network"])


func test_get_log_tags_with_multiple_tags() -> void:
	var tags: Array = DLoggerPanelFormat.get_log_tags(
		_make_log("x", "INFO", "D-Logger", "net|audio")
	)
	assert_array(tags).contains_exactly(["net", "audio"])


func test_get_log_tags_no_category_uses_prefix() -> void:
	var tags: Array = DLoggerPanelFormat.get_log_tags(
		_make_log("x", "INFO", "MyModule")
	)
	assert_array(tags).contains_exactly(["MyModule"])


func test_get_log_tags_no_category_default_prefix() -> void:
	var tags: Array = DLoggerPanelFormat.get_log_tags(
		_make_log("x")
	)
	assert_array(tags).contains_exactly(["Default"])


# ------------- [format_log_plain] -------------
func test_format_log_plain_has_no_bbcode() -> void:
	var result: String = DLoggerPanelFormat.format_log_plain(_make_log("hello world"))
	assert_bool(result.contains("[b]")).is_false()
	assert_bool(result.contains("[/b]")).is_false()
	assert_str(result).contains("[INFO] hello world")


func test_format_log_plain_with_count() -> void:
	var log := _make_log("hello")
	log["count"] = 3
	var result: String = DLoggerPanelFormat.format_log_plain(log)
	assert_str(result).contains("(x3)")


# ------------- [format_log] -------------
func test_format_log_info_uses_cyan() -> void:
	var result: String = DLoggerPanelFormat.format_log(
		_make_log("hello"), DLoggerSearch.new(), false, 0.0
	)
	assert_str(result).contains("[color=cyan]")
	assert_bool(result.contains("[color=red]")).is_false()


func test_format_log_error_uses_red() -> void:
	var result: String = DLoggerPanelFormat.format_log(
		_make_log("boom", "ERROR"), DLoggerSearch.new(), false, 0.0
	)
	assert_str(result).contains("[color=red]")


func test_format_log_selected_uses_white() -> void:
	var result: String = DLoggerPanelFormat.format_log(
		_make_log("hello"), DLoggerSearch.new(), false, 0.0, true
	)
	assert_str(result).contains("[color=#ffffff]")


func test_format_log_search_highlight() -> void:
	var search := DLoggerSearch.new()
	search.query = "inject"
	var result: String = DLoggerPanelFormat.format_log(
		_make_log("inject me"), search, false, 0.0
	)
	assert_str(result).contains(
		"[bgcolor=yellow][color=black]inject[/color][/bgcolor]"
	)


func test_format_log_escapes_bbcode_in_message() -> void:
	var search := DLoggerSearch.new()
	var result: String = DLoggerPanelFormat.format_log(
		_make_log("[b]inject[/b]"), search, false, 0.0
	)
	assert_str(result).contains("[lb]b[rb]inject[lb]/b[rb]")
	assert_bool(result.contains("[b]inject[/b]")).is_false()


func test_format_log_relative_time() -> void:
	var result: String = DLoggerPanelFormat.format_log(
		_make_log("late"), DLoggerSearch.new(), true, 1.0
	)
	# time 1.0 - max_time 1.0 = 0.0s
	assert_str(result).contains("[  0.000s]")
