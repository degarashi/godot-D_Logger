class_name DLoggerArrayTest
extends GdUnitTestSuite

const _ARRAY = preload("res://addons/d_logger/logger/d_logger_array.gd")
const _QUIET = preload("res://addons/d_logger/logger/d_logger_quiet.gd")
const _FULL = preload("res://addons/d_logger/logger/d_logger_full.gd")


# ------------- [Constructor] -------------
func test_init() -> void:
	var arr := _ARRAY.new()
	assert_object(arr).is_not_null()
	assert_bool(arr.is_empty()).is_true()


# ------------- [add] -------------
func test_add_logger() -> void:
	var arr := _ARRAY.new()
	var quiet := _QUIET.new()
	arr.add(quiet)
	assert_bool(arr.is_empty()).is_false()
	assert_int(arr._list.size()).is_equal(1)


func test_add_multiple_loggers() -> void:
	var arr := _ARRAY.new()
	arr.add(_QUIET.new())
	arr.add(_QUIET.new())
	arr.add(_QUIET.new())
	assert_int(arr._list.size()).is_equal(3)


# ------------- [clear] -------------
func test_clear() -> void:
	var arr := _ARRAY.new()
	arr.add(_QUIET.new())
	arr.add(_QUIET.new())
	assert_bool(arr.is_empty()).is_false()
	arr.clear()
	assert_bool(arr.is_empty()).is_true()
	assert_int(arr._list.size()).is_equal(0)


# ------------- [is_empty] -------------
func test_is_empty_initial() -> void:
	var arr := _ARRAY.new()
	assert_bool(arr.is_empty()).is_true()


func test_is_empty_after_add() -> void:
	var arr := _ARRAY.new()
	arr.add(_QUIET.new())
	assert_bool(arr.is_empty()).is_false()


func test_is_empty_after_clear() -> void:
	var arr := _ARRAY.new()
	arr.add(_QUIET.new())
	arr.clear()
	assert_bool(arr.is_empty()).is_true()


# ------------- [Level Checks] -------------
func test_is_debug_enabled() -> void:
	var arr := _ARRAY.new()
	assert_bool(arr.is_debug_enabled()).is_true()


func test_is_info_enabled() -> void:
	var arr := _ARRAY.new()
	assert_bool(arr.is_info_enabled()).is_true()


func test_is_warn_enabled() -> void:
	var arr := _ARRAY.new()
	assert_bool(arr.is_warn_enabled()).is_true()


func test_is_error_enabled() -> void:
	var arr := _ARRAY.new()
	assert_bool(arr.is_error_enabled()).is_true()


# ------------- [Dispatch] -------------
func test_dispatch_debug() -> void:
	var arr := _ARRAY.new()
	arr.add(_QUIET.new())
	# Should not crash, dispatches to child
	assert_bool(arr.debug("test")).is_true()


func test_dispatch_info() -> void:
	var arr := _ARRAY.new()
	arr.add(_QUIET.new())
	assert_bool(arr.info("test")).is_true()


func test_dispatch_warn() -> void:
	var arr := _ARRAY.new()
	arr.add(_QUIET.new())
	assert_bool(arr.warn("test")).is_true()


func test_dispatch_error() -> void:
	var arr := _ARRAY.new()
	arr.add(_QUIET.new())
	assert_bool(arr.error("test")).is_true()


func test_dispatch_to_multiple_loggers() -> void:
	var arr := _ARRAY.new()
	arr.add(_QUIET.new())
	arr.add(_QUIET.new())
	# Should dispatch to both without error
	assert_bool(arr.info("multi-dispatch")).is_true()


# ------------- [Return Values] -------------
func test_all_methods_return_true() -> void:
	var arr := _ARRAY.new()
	arr.add(_QUIET.new())
	assert_bool(arr.debug("msg")).is_true()
	assert_bool(arr.info("msg")).is_true()
	assert_bool(arr.warn("msg")).is_true()
	assert_bool(arr.error("msg")).is_true()


# ------------- [Error Handling] -------------
func test_add_null_throws_error() -> void:
	var arr := _ARRAY.new()
	assert_error(func(): arr.add(null))


func test_dispatch_empty_list() -> void:
	var arr := _ARRAY.new()
	# Empty array should still return true for all methods
	assert_bool(arr.debug("test")).is_true()
	assert_bool(arr.info("test")).is_true()
	assert_bool(arr.warn("test")).is_true()
	assert_bool(arr.error("test")).is_true()


# ------------- [Mixed Logger Types] -------------
func test_dispatch_to_mixed_logger_types() -> void:
	var arr := _ARRAY.new()
	arr.add(_FULL.new())
	arr.add(_QUIET.new())
	# Dispatch all levels to mixed types - should not crash
	assert_bool(arr.debug("mixed test")).is_true()
	assert_bool(arr.info("mixed test")).is_true()
	assert_bool(arr.warn("mixed test")).is_true()
	assert_bool(arr.error("mixed test")).is_true()


func test_dispatch_with_values_to_mixed() -> void:
	var arr := _ARRAY.new()
	arr.add(_FULL.new())
	arr.add(_QUIET.new())
	assert_bool(arr.info("val: {0}", [42])).is_true()
	assert_bool(arr.info("dict: {k}", {"k": "v"})).is_true()
	assert_bool(arr.info("raw: {0}", "str")).is_true()


func test_dispatch_with_category_context_to_mixed() -> void:
	var arr := _ARRAY.new()
	arr.add(_FULL.new())
	arr.add(_QUIET.new())
	var node := Node.new()
	assert_bool(arr.info("cat msg", [], "Network", node)).is_true()
	assert_bool(arr.warn("cat msg", [], "System", node, "CUSTOM")).is_true()
	node.free()
