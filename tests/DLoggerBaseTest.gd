class_name DLoggerBaseTest
extends GdUnitTestSuite

const _BASE = preload("res://addons/d_logger/logger/d_logger_base.gd")


# ------------- [Constructor] -------------
func test_init() -> void:
	var logger := _BASE.new()
	assert_object(logger).is_not_null()


# ------------- [Level Checks] -------------
func test_is_debug_enabled_default() -> void:
	var logger := _BASE.new()
	assert_bool(logger.is_debug_enabled()).is_true()


func test_is_info_enabled_default() -> void:
	var logger := _BASE.new()
	assert_bool(logger.is_info_enabled()).is_true()


func test_is_warn_enabled_default() -> void:
	var logger := _BASE.new()
	assert_bool(logger.is_warn_enabled()).is_true()


func test_is_error_enabled_default() -> void:
	var logger := _BASE.new()
	assert_bool(logger.is_error_enabled()).is_true()


# ------------- [Log Methods Return True] -------------
func test_debug_returns_true() -> void:
	var logger := _BASE.new()
	assert_bool(logger.debug("test")).is_true()


func test_info_returns_true() -> void:
	var logger := _BASE.new()
	assert_bool(logger.info("test")).is_true()


func test_warn_returns_true() -> void:
	var logger := _BASE.new()
	assert_bool(logger.warn("test")).is_true()


func test_error_returns_true() -> void:
	var logger := _BASE.new()
	assert_bool(logger.error("test")).is_true()


# ------------- [_output is a No-op] -------------
func test_output_noop() -> void:
	var logger := _BASE.new()
	# Calling _output should not crash
	logger._output("test", [], "", null, "", null, "DEBUG")
	assert_bool(true).is_true()


# ------------- [Log Method with Parameters] -------------
func test_debug_with_values() -> void:
	var logger := _BASE.new()
	assert_bool(logger.debug("Value: {0}", [42])).is_true()


func test_info_with_category() -> void:
	var logger := _BASE.new()
	assert_bool(logger.info("msg", [], "System")).is_true()


func test_warn_with_context() -> void:
	var logger := _BASE.new()
	var node := Node.new()
	assert_bool(logger.warn("msg", [], "", node)).is_true()
	node.free()


func test_error_with_prefix() -> void:
	var logger := _BASE.new()
	assert_bool(logger.error("msg", [], "", null, "CUSTOM")).is_true()
