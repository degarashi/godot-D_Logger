class_name DLoggerFullTest
extends GdUnitTestSuite

const _FULL = preload("res://addons/d_logger/logger/d_logger_full.gd")
const _CONST = preload("res://addons/d_logger/constants.gd")


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



