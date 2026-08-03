class_name DLoggerNodeBaseTest
extends GdUnitTestSuite

const _NODE_BASE = preload("res://addons/d_logger/d_logger_node_base.gd")
const _CLASS = preload("res://addons/d_logger/d_logger.gd")
const _CONST = preload("res://addons/d_logger/constants.gd")


# ------------- [Constructor] -------------
func test_init() -> void:
	var node := _NODE_BASE.new()
	assert_object(node).is_not_null()
	node.free()


func test_is_node() -> void:
	var node := _NODE_BASE.new()
	assert_bool(node is Node)
	node.free()


# ------------- [get_logger] -------------
func test_get_logger_returns_logger() -> void:
	var node := _NODE_BASE.new()
	var logger := node.get_logger()
	# _logger is set by subclass, default is null
	# This tests the getter exists and returns the internal logger
	assert_object(node._logger).is_null()
	node.free()


func test_set_and_get_logger() -> void:
	var node := _NODE_BASE.new()
	var logger := _CLASS.new("TEST")
	node._logger = logger
	assert_object(node.get_logger()).is_equal(logger)
	node.free()


# ------------- [Level Check Forwarding] -------------
func test_is_debug_enabled_forwards() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(node.is_debug_enabled()).is_true()
	node.free()


func test_is_info_enabled_forwards() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(node.is_info_enabled()).is_true()
	node.free()


func test_is_warn_enabled_forwards() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(node.is_warn_enabled()).is_true()
	node.free()


func test_is_error_enabled_forwards() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(node.is_error_enabled()).is_true()
	node.free()


func test_is_debug_disabled_when_level_is_info() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.INFO)
	assert_bool(node.is_debug_enabled()).is_false()
	node.free()


func test_is_info_disabled_when_level_is_warn() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.WARN)
	assert_bool(node.is_info_enabled()).is_false()
	node.free()


func test_is_warn_disabled_when_level_is_error() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.ERROR)
	assert_bool(node.is_warn_enabled()).is_false()
	node.free()


# ------------- [Log Method Forwarding] -------------
func test_debug_forwards() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(node.debug("test debug")).is_true()
	node.free()


func test_info_forwards() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(node.info("test info")).is_true()
	node.free()


func test_warn_forwards() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(node.warn("test warn")).is_true()
	node.free()


func test_error_forwards() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(node.error("test error")).is_true()
	node.free()


# ------------- [Parameter Forwarding] -------------
func test_debug_with_values() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(node.debug("Value: {0}", [42])).is_true()
	node.free()


func test_info_with_category() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(node.info("msg", [], "System")).is_true()
	node.free()


func test_warn_with_context() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	var child := Node.new()
	node.add_child(child)
	assert_bool(node.warn("msg", [], "", child)).is_true()
	child.free()
	node.free()


func test_error_with_prefix() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(node.error("msg", [], "", null, "CUSTOM")).is_true()
	node.free()


# ------------- [Level Filtering via Forwarding] -------------
func test_debug_not_dispatched_when_disabled() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.INFO)
	# debug() should still return true even if level is disabled
	assert_bool(node.debug("should not dispatch")).is_true()
	node.free()


func test_info_not_dispatched_when_level_is_warn() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.WARN)
	assert_bool(node.info("should not dispatch")).is_true()
	node.free()


# ------------- [Null Logger Safety] -------------
func test_get_logger_no_crash_when_null() -> void:
	var node := _NODE_BASE.new()
	assert_object(node.get_logger()).is_null()
	node.free()


func test_forwarding_is_safe_when_logger_is_null() -> void:
	var node := _NODE_BASE.new()

	assert_bool(node.is_debug_enabled()).is_false()
	assert_bool(node.is_info_enabled()).is_false()
	assert_bool(node.is_warn_enabled()).is_false()
	assert_bool(node.is_error_enabled()).is_false()
	assert_bool(node.debug("debug")).is_true()
	assert_bool(node.info("info")).is_true()
	assert_bool(node.warn("warn")).is_true()
	assert_bool(node.error("error")).is_true()
	node.free()


# ------------- [benchmark Forwarding] -------------
func test_benchmark_forwards_to_logger() -> void:
	var node := _NODE_BASE.new()
	node._logger = _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	var result: Variant = node.benchmark("forwarded_call", func() -> int: return 7)
	assert_int(result).is_equal(7)
	node.free()


func test_benchmark_null_logger_returns_null() -> void:
	var node := _NODE_BASE.new()
	assert_object(node.benchmark("no_logger", func() -> void: pass)).is_null()
	node.free()
