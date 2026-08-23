class_name DLoggerFuncTest
extends GdUnitTestSuite

const _FUNC = preload("res://addons/d_logger/common.gd")
const _CONST = preload("res://addons/d_logger/constants.gd")
const _BASE = preload("res://addons/d_logger/logger/d_logger_base.gd")
const _CLASS = preload("res://addons/d_logger/d_logger.gd")
const _NODE_BASE = preload("res://addons/d_logger/d_logger_node_base.gd")


# ------------- [has_logger_interface] -------------
func test_has_logger_interface_with_valid_logger() -> void:
	var logger := preload("res://addons/d_logger/d_logger.gd").new()
	assert_bool(_FUNC.has_logger_interface(logger)).is_true()


func test_has_logger_interface_with_invalid_object() -> void:
	var obj := RefCounted.new()
	assert_bool(_FUNC.has_logger_interface(obj)).is_false()


func test_has_logger_interface_with_node() -> void:
	var node := Node.new()
	assert_bool(_FUNC.has_logger_interface(node)).is_false()
	node.free()


func test_has_logger_interface_with_null() -> void:
	# Regression: null input must be handled gracefully, not crash.
	assert_bool(_FUNC.has_logger_interface(null)).is_false()


# ------------- [escape_bbcode] -------------
func test_escape_bbcode_escapes_brackets() -> void:
	assert_str(_FUNC.escape_bbcode("[b]bold[/b]")).is_equal(
		"[lb]b[rb]bold[lb]/b[rb]"
	)


func test_escape_bbcode_plain_text_unchanged() -> void:
	assert_str(_FUNC.escape_bbcode("hello world 42")).is_equal("hello world 42")


# ------------- [has_unresolved_placeholder] -------------
func test_has_unresolved_placeholder_positional_leftover() -> void:
	# A {0} placeholder that survived formatting (e.g. Dictionary was
	# passed for a positional placeholder) must be detected.
	assert_bool(_FUNC.has_unresolved_placeholder("attack failed {0}")).is_true()


func test_has_unresolved_placeholder_named_leftover() -> void:
	# A {name} placeholder that survived formatting (e.g. Array was passed
	# for a named placeholder) must be detected.
	(
		assert_bool(_FUNC.has_unresolved_placeholder("player {name} joined"))
		. is_true()
	)


func test_has_unresolved_placeholder_resolved_text_is_clean() -> void:
	assert_bool(_FUNC.has_unresolved_placeholder("attack failed 3")).is_false()


func test_has_unresolved_placeholder_plain_text_with_braces() -> void:
	# Braces not forming a placeholder key (e.g. code/JSON snippets) are
	# not flagged.
	assert_bool(_FUNC.has_unresolved_placeholder('{"key": "value"}')).is_false()


func test_has_unresolved_placeholder_empty_braces_not_flagged() -> void:
	assert_bool(_FUNC.has_unresolved_placeholder("empty {} braces")).is_false()


func test_has_unresolved_placeholder_after_empty_braces() -> void:
	# An empty {} pair earlier in the text must not stop detection
	# of a real placeholder that follows it.
	assert_bool(_FUNC.has_unresolved_placeholder("empty {} and {0}")).is_true()


func test_has_unresolved_placeholder_nested_in_nonkey_body() -> void:
	# A placeholder nested after a non-key brace region must still be
	# found once scanning resumes at the next '{'.
	assert_bool(_FUNC.has_unresolved_placeholder("{ broken {0}")).is_true()


func test_has_unresolved_placeholder_empty_braces_alone() -> void:
	assert_bool(_FUNC.has_unresolved_placeholder("{}")).is_false()


func test_has_unresolved_placeholder_no_text_returns_false() -> void:
	assert_bool(_FUNC.has_unresolved_placeholder("")).is_false()


# ------------- [get_logger] -------------
func test_get_logger_with_null() -> void:
	assert_object(_FUNC.get_logger(null)).is_null()


func test_get_logger_with_valid_logger() -> void:
	var logger := preload("res://addons/d_logger/d_logger.gd").new()
	assert_object(_FUNC.get_logger(logger)).is_not_null()


func test_get_logger_with_node_without_logger() -> void:
	var node := Node.new()
	assert_object(_FUNC.get_logger(node)).is_null()
	node.free()


# ------------- [is_logger] -------------
func test_is_logger_with_valid_logger() -> void:
	var logger := preload("res://addons/d_logger/d_logger.gd").new()
	assert_bool(_FUNC.is_logger(logger)).is_true()


func test_is_logger_with_invalid_object() -> void:
	var obj := RefCounted.new()
	assert_bool(_FUNC.is_logger(obj)).is_false()


# ------------- [get_object_string] -------------
func test_get_object_string_with_node() -> void:
	var node := Node.new()
	node.name = "TestNode"
	var result := _FUNC.get_object_string(node)
	assert_str(result).contains("TestNode")
	node.free()


func test_get_object_string_with_object() -> void:
	var obj := RefCounted.new()
	var result := _FUNC.get_object_string(obj)
	assert_str(result).contains("RefCounted")


# ------------- [get_caller_info] -------------
func test_get_caller_info_returns_empty_for_debug() -> void:
	var result := _FUNC.get_caller_info("DEBUG")
	assert_dict(result).is_empty()


func test_get_caller_info_returns_empty_for_info() -> void:
	var result := _FUNC.get_caller_info("INFO")
	assert_dict(result).is_empty()


func test_get_caller_info_returns_dict_for_warn() -> void:
	var result := _FUNC.get_caller_info("WARN")
	# In test context, should return a dict with file/line/display
	assert_dict(result).is_not_empty()
	assert_bool(result.has("file")).is_true()
	assert_bool(result.has("line")).is_true()
	assert_bool(result.has("display")).is_true()


func test_get_caller_info_returns_dict_for_error() -> void:
	var result := _FUNC.get_caller_info("ERROR")
	assert_dict(result).is_not_empty()
	assert_bool(result.has("file")).is_true()
	assert_bool(result.has("line")).is_true()
	assert_bool(result.has("display")).is_true()


# ------------- [get_source_string] -------------
func test_get_source_string_default_prefix_no_category() -> void:
	var result := _FUNC.get_source_string("D-Logger", "")
	assert_str(result).contains("D-Logger")


func test_get_source_string_custom_prefix_no_category() -> void:
	var result := _FUNC.get_source_string("MY_APP", "")
	assert_str(result).contains("MY_APP")


func test_get_source_string_with_category() -> void:
	var result := _FUNC.get_source_string("D-Logger", "System")
	assert_str(result).contains("System")


func test_get_source_string_default_prefix_with_category() -> void:
	var result := _FUNC.get_source_string("D-Logger", "Gameplay")
	assert_str(result).contains("Gameplay")


func test_get_source_string_multiple_tags() -> void:
	var result := _FUNC.get_source_string("D-Logger", "AI|Combat")
	assert_str(result).contains("AI")
	assert_str(result).contains("Combat")


# ------------- [format_log] -------------
func test_format_log_basic() -> void:
	_FUNC.set_time_cache(1.5, 100)
	var result := _FUNC.format_log("Hello", "", "INFO", null, "D-Logger")
	assert_str(result).contains("Hello")
	assert_str(result).contains("INFO")
	assert_str(result).contains("D-Logger")
	_FUNC.clear_time_cache()


func test_format_log_with_category() -> void:
	_FUNC.set_time_cache(2.0, 200)
	var result := _FUNC.format_log(
		"Test msg", "Network", "WARN", null, "D-Logger"
	)
	assert_str(result).contains("Test msg")
	assert_str(result).contains("Network")
	assert_str(result).contains("WARN")
	_FUNC.clear_time_cache()


func test_format_log_with_context() -> void:
	_FUNC.set_time_cache(3.0, 300)
	var node := Node.new()
	node.name = "Player"
	var result := _FUNC.format_log("Msg", "", "ERROR", node, "D-Logger")
	assert_str(result).contains("Msg")
	assert_str(result).contains("Player")
	_FUNC.clear_time_cache()
	node.free()


func test_format_log_with_caller_info() -> void:
	_FUNC.set_time_cache(4.0, 400)
	var caller := {"file": "test.gd", "line": 42, "display": "[test.gd:42]"}
	var result := _FUNC.format_log(
		"Caller test", "", "WARN", null, "D-Logger", caller
	)
	assert_str(result).contains("Caller test")
	assert_str(result).contains("test.gd")
	_FUNC.clear_time_cache()


# ------------- [time_cache] -------------
func test_time_cache_set_and_clear() -> void:
	_FUNC.set_time_cache(5.0, 500)
	_FUNC.clear_time_cache()
	# After clear, format_log should compute fresh values
	var result := _FUNC.format_log("After clear", "", "INFO", null, "D-Logger")
	assert_str(result).contains("After clear")


# ------------- [get_formatted_line] -------------
func test_get_formatted_line_basic() -> void:
	var result := _FUNC.get_formatted_line(
		1.234, 100, "[D-Logger]", {}, "", "INFO", "Hello"
	)
	assert_str(result).contains("Hello")
	assert_str(result).contains("INFO")
	assert_str(result).contains("D-Logger")


func test_get_formatted_line_with_caller() -> void:
	var caller := {"file": "main.gd", "line": 10, "display": "[main.gd:10]"}
	var result := _FUNC.get_formatted_line(
		2.0, 200, "[D-Logger]", caller, "", "WARN", "Warning msg"
	)
	assert_str(result).contains("main.gd:10")
	assert_str(result).contains("Warning msg")


func test_get_formatted_line_bbcode_escapes_caller_and_context() -> void:
	# Caller paths and node names may contain square brackets; in BBCode
	# mode they must be escaped so they cannot inject markup.
	var caller := {"file": "res://[x].gd", "line": 3, "display": "[x].gd:3"}
	var result := _FUNC.get_formatted_line(
		2.0, 200, "[D-Logger]", caller, "[Evil[url=]ctx]", "WARN", "msg", true
	)
	assert_int(result.count("[url=")).is_equal(1)
	assert_str(result).contains("url=res://[lb]x[rb].gd:3")
	assert_str(result).contains("[lb]x[rb].gd:3")
	assert_str(result).contains("[lb]Evil[lb]url=[rb]ctx[rb]")


func test_get_formatted_line_plain_keeps_raw_brackets() -> void:
	var caller := {"file": "res://[x].gd", "line": 3, "display": "[x].gd:3"}
	var result := _FUNC.get_formatted_line(
		2.0, 200, "[D-Logger]", caller, "[Evil[url=]ctx]", "WARN", "msg", false
	)
	# Plain mode must not wrap anything in link tags (the raw context
	# string itself may legitimately contain "[url=", so check for the
	# closing tag instead).
	assert_int(result.count("[/url]")).is_equal(0)
	assert_str(result).contains(" [x].gd:3")
	assert_str(result).contains(" [Evil[url=]ctx]")


# ------------- [find_logger_from_ancestor] -------------
func test_find_logger_from_ancestor_finds_logger() -> void:
	var root := Node.new()
	root.name = "Root"
	var logger_node := _NODE_BASE.new()
	logger_node.name = "LoggerNode"
	logger_node._logger = _CLASS.new("TEST")
	root.add_child(logger_node)
	var child := Node.new()
	child.name = "Child"
	logger_node.add_child(child)
	var result := _FUNC.find_logger_from_ancestor(child)
	assert_object(result).is_not_null()
	child.free()
	logger_node.free()
	root.free()


func test_find_logger_from_ancestor_no_logger() -> void:
	var root := Node.new()
	root.name = "Root"
	var child := Node.new()
	child.name = "Child"
	root.add_child(child)
	var result := _FUNC.find_logger_from_ancestor(child)
	assert_object(result).is_null()
	child.free()
	root.free()


func test_find_logger_from_ancestor_null_input() -> void:
	var result := _FUNC.find_logger_from_ancestor(null)
	assert_object(result).is_null()


func test_find_logger_from_ancestor_deep_hierarchy() -> void:
	var root := Node.new()
	root.name = "Root"
	var logger_node := _NODE_BASE.new()
	logger_node.name = "LoggerNode"
	logger_node._logger = _CLASS.new("TEST")
	root.add_child(logger_node)
	var mid := Node.new()
	mid.name = "Mid"
	logger_node.add_child(mid)
	var deep := Node.new()
	deep.name = "Deep"
	mid.add_child(deep)
	var result := _FUNC.find_logger_from_ancestor(deep)
	assert_object(result).is_not_null()
	deep.free()
	mid.free()
	logger_node.free()
	root.free()


# ------------- [get_source_string with BBCode] -------------
func test_get_source_string_with_bbcode() -> void:
	var result := _FUNC.get_source_string("D-Logger", "", true)
	assert_str(result).contains("[url=")
	assert_str(result).contains("[/url]")


func test_get_source_string_empty_prefix() -> void:
	var result := _FUNC.get_source_string("", "")
	assert_str(result).is_equal("[]")
	var result_cat := _FUNC.get_source_string("", "Test")
	assert_str(result_cat).is_equal("[:Test]")


func test_get_source_string_bbcode_escapes_brackets_in_prefix() -> void:
	# A bracket in the prefix must be escaped so the RichTextLabel parser
	# does not see a premature [/url] or [url=...] injection. Both the
	# URL target and the display label are protected. The input "Net[work"
	# has only an opening bracket, so [lb] should appear twice (URL and
	# display) and [rb] should not appear at all.
	var result := _FUNC.get_source_string("Net[work", "", true)
	assert_bool(result.contains("Net[work")).is_false()
	assert_str(result).contains("Net[lb]work")
	assert_int(result.count("[lb]")).is_equal(2)
	assert_int(result.count("[rb]")).is_equal(0)


func test_get_source_string_bbcode_escapes_brackets_in_category_tag() -> void:
	# A category tag containing "][" must not survive unescaped into the
	# [url=...] markup — that would close the tag and re-open it as a
	# different URL the user could click as if it were the intended
	# filter target. Same protection applies to each tag in a "|"-split
	# category.
	var result := _FUNC.get_source_string("D-Logger", "AI][injected", true)
	assert_bool(result.contains("AI][injected")).is_false()
	assert_str(result).contains("AI[rb][lb]injected")


# ------------- [get_object_string edge cases] -------------
func test_get_object_string_with_long_name() -> void:
	var long_name := "ThisIsAVeryLongNodeNameThatExceedsTypicalLengthLimits_1234567890"
	var node := Node.new()
	node.name = long_name
	var result := _FUNC.get_object_string(node)
	assert_str(result).contains(long_name)
	node.free()


# ------------- [Autoload Ownership] -------------
const _AUTOLOAD_PATH := "res://addons/d_logger/d_logger_node.tscn"
const _AUTOLOAD_UID := "uid://dk8w65jl35vbd"


func test_is_autoload_ours_matching_res_path() -> void:
	(
		assert_bool(_FUNC.is_autoload_ours(_AUTOLOAD_PATH, _AUTOLOAD_PATH))
		. is_true()
	)


func test_is_autoload_ours_star_prefixed_res_path() -> void:
	(
		assert_bool(
			_FUNC.is_autoload_ours("*" + _AUTOLOAD_PATH, _AUTOLOAD_PATH)
		)
		. is_true()
	)


func test_is_autoload_ours_matching_uid() -> void:
	assert_bool(_FUNC.is_autoload_ours(_AUTOLOAD_UID, _AUTOLOAD_PATH)).is_true()


func test_is_autoload_ours_star_prefixed_uid() -> void:
	(
		assert_bool(_FUNC.is_autoload_ours("*" + _AUTOLOAD_UID, _AUTOLOAD_PATH))
		. is_true()
	)


func test_is_autoload_ours_empty_value() -> void:
	assert_bool(_FUNC.is_autoload_ours("", _AUTOLOAD_PATH)).is_false()


func test_is_autoload_ours_other_res_path() -> void:
	(
		assert_bool(
			_FUNC.is_autoload_ours("res://other/logger.tscn", _AUTOLOAD_PATH)
		)
		. is_false()
	)


func test_is_autoload_ours_other_uid() -> void:
	(
		assert_bool(
			_FUNC.is_autoload_ours("uid://0123456789abc", _AUTOLOAD_PATH)
		)
		. is_false()
	)


func test_is_autoload_ours_trailing_whitespace_not_trimmed() -> void:
	(
		assert_bool(
			_FUNC.is_autoload_ours(_AUTOLOAD_PATH + " ", _AUTOLOAD_PATH)
		)
		. is_false()
	)
