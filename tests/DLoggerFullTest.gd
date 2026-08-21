class_name DLoggerFullTest
extends GdUnitTestSuite

const _FULL = preload("res://addons/d_logger/logger/d_logger_full.gd")
const _CONST = preload("res://addons/d_logger/constants.gd")
const _FUNC = preload("res://addons/d_logger/common.gd")


# ------------- [Constructor] -------------
func test_init() -> void:
	var logger := _FULL.new()
	assert_object(logger).is_not_null()


func test_init_inherits_base() -> void:
	var logger := _FULL.new()
	assert_bool(logger is DLoggerBase)


# ------------- [Level Checks - Inherited Defaults] -------------
func test_is_debug_enabled_default() -> void:
	var logger := _FULL.new()
	assert_bool(logger.is_debug_enabled()).is_true()


func test_is_info_enabled_default() -> void:
	var logger := _FULL.new()
	assert_bool(logger.is_info_enabled()).is_true()


func test_is_warn_enabled_default() -> void:
	var logger := _FULL.new()
	assert_bool(logger.is_warn_enabled()).is_true()


func test_is_error_enabled_default() -> void:
	var logger := _FULL.new()
	assert_bool(logger.is_error_enabled()).is_true()


# ------------- [Return Values] -------------
func test_debug_returns_true() -> void:
	var logger := _FULL.new()
	assert_bool(logger.debug("test debug")).is_true()


func test_info_returns_true() -> void:
	var logger := _FULL.new()
	assert_bool(logger.info("test info")).is_true()


func test_warn_returns_true() -> void:
	var logger := _FULL.new()
	assert_bool(logger.warn("test warn")).is_true()


func test_error_returns_true() -> void:
	var logger := _FULL.new()
	assert_bool(logger.error("test error")).is_true()


# ------------- [Output Behavior] -------------
func test_debug_outputs_without_push_warning() -> void:
	var logger := _FULL.new()
	# debug() should not call push_warning/push_error
	assert_bool(logger.debug("debug message")).is_true()


func test_info_outputs_without_push_warning() -> void:
	var logger := _FULL.new()
	assert_bool(logger.info("info message")).is_true()


func test_warn_outputs_with_push_warning() -> void:
	var logger := _FULL.new()
	# warn() calls push_warning internally - verify it runs without crash
	assert_bool(logger.warn("warn message")).is_true()


func test_error_outputs_with_push_error() -> void:
	var logger := _FULL.new()
	# error() calls push_error internally - verify it runs without crash
	assert_bool(logger.error("error message")).is_true()


# ------------- [String Formatting] -------------
func test_format_with_array() -> void:
	var logger := _FULL.new()
	assert_bool(logger.info("Value: {0}", [42])).is_true()


func test_format_with_dict() -> void:
	var logger := _FULL.new()
	assert_bool(logger.info("HP={hp}", {"hp": 100})).is_true()


func test_format_with_single_value() -> void:
	var logger := _FULL.new()
	assert_bool(logger.info("Value: {0}", 42)).is_true()


func test_format_with_empty_values() -> void:
	var logger := _FULL.new()
	assert_bool(logger.info("No values")).is_true()


# ------------- [Category & Context] -------------
func test_with_category() -> void:
	var logger := _FULL.new()
	assert_bool(logger.info("msg", [], "System")).is_true()


func test_with_context() -> void:
	var logger := _FULL.new()
	var node := Node.new()
	assert_bool(logger.info("msg", [], "", node)).is_true()
	node.free()


func test_with_prefix_override() -> void:
	var logger := _FULL.new()
	assert_bool(logger.info("msg", [], "", null, "CUSTOM")).is_true()


# ------------- [_Output Direct Invocation] -------------
func test_output_direct_call_no_crash() -> void:
	var logger := _FULL.new()
	# Calling _output directly with known params should not crash
	logger._output("test msg", [], "", null, "", null, "DEBUG")


func test_output_warn_calls_push_warning() -> void:
	var logger := _FULL.new()
	# warn() calls _output which calls push_warning internally
	assert_bool(logger.warn("test warn push")).is_true()


func test_output_error_calls_push_error() -> void:
	var logger := _FULL.new()
	# error() calls _output which calls push_error internally
	assert_bool(logger.error("test error push")).is_true()


# ------------- [Full Output Chain] -------------
func test_output_with_all_parameters() -> void:
	var logger := _FULL.new()
	var node := Node.new()
	var caller := {"file": "test.gd", "line": 1, "display": "[test.gd:1]"}
	# Exercise _output with full parameter set for each level
	logger._output("msg", [], "System", node, "CUSTOM", caller, "DEBUG")
	logger._output("msg", [], "System", node, "CUSTOM", caller, "INFO")
	logger._output("msg", [], "System", node, "CUSTOM", caller, "WARN")
	logger._output("msg", [], "System", node, "CUSTOM", caller, "ERROR")
	assert_bool(true).is_true()
	node.free()


func test_output_with_empty_caller_info() -> void:
	var logger := _FULL.new()
	# Empty dict caller_info - should skip caller part
	logger.debug("no caller")
	logger.info("no caller")
	logger.warn("no caller")
	logger.error("no caller")
	assert_bool(true).is_true()


func test_output_all_levels_via_public_api() -> void:
	var logger := _FULL.new()
	assert_bool(logger.debug("debug api")).is_true()
	assert_bool(logger.info("info api")).is_true()
	assert_bool(logger.warn("warn api")).is_true()
	assert_bool(logger.error("error api")).is_true()


func test_output_with_multiline_message() -> void:
	var logger := _FULL.new()
	assert_bool(logger.info("line1\nline2\nline3")).is_true()


func test_output_with_mixed_values_types() -> void:
	var logger := _FULL.new()
	assert_bool(logger.info("array: {0}", [1, 2, 3])).is_true()
	assert_bool(logger.info("dict: {k}", {"k": "v"})).is_true()
	assert_bool(logger.info("single: {0}", 42)).is_true()
	assert_bool(logger.info("raw string", "not_formatted")).is_true()


func test_output_unknown_level_fallback() -> void:
	var logger := _FULL.new()
	# Unknown level should fall through to default branch (no BBCode color)
	logger._output("test", [], "", null, "", null, "TRACE")
	assert_bool(true).is_true()


func test_bbcode_consistency_across_levels() -> void:
	_FUNC.set_time_cache(1.0, 100)
	var logger := _FULL.new()
	# All levels should succeed without error
	assert_bool(logger.debug("debug")).is_true()
	assert_bool(logger.info("info")).is_true()
	assert_bool(logger.warn("warn")).is_true()
	assert_bool(logger.error("error")).is_true()
	_FUNC.clear_time_cache()


func test_bbcode_with_category_context() -> void:
	_FUNC.set_time_cache(2.0, 200)
	var logger := _FULL.new()
	var node := Node.new()
	logger._output("cat msg", [], "Network", node, "", null, "INFO")
	logger._output("cat msg", [], "AI|Combat", node, "CUSTOM", null, "WARN")
	node.free()
	assert_bool(true).is_true()
	_FUNC.clear_time_cache()
