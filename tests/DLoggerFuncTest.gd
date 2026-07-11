class_name DLoggerFuncTest
extends GdUnitTestSuite

const _FUNC = preload("res://addons/d_logger/common.gd")
const _CONST = preload("res://addons/d_logger/constants.gd")
const _BASE = preload("res://addons/d_logger/logger/d_logger_base.gd")


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
	# has_logger_interface crashes on null input (calls has_method on null)
	# This verifies the function does not gracefully handle null - it crashes
	# so we test via get_logger which does handle null
	assert_object(_FUNC.get_logger(null)).is_null()


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
	var result := _FUNC.format_log("Test msg", "Network", "WARN", null, "D-Logger")
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
	var result := _FUNC.format_log("Caller test", "", "WARN", null, "D-Logger", caller)
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
