class_name DLoggerNodeTest
extends GdUnitTestSuite

const _NODE = preload("res://addons/d_logger/d_logger_node.gd")
const _NODE_BASE = preload("res://addons/d_logger/d_logger_node_base.gd")
const _CLASS = preload("res://addons/d_logger/d_logger.gd")
const _INIT_PARAM = preload("res://addons/d_logger/d_logger_init_param.gd")
const _CONST = preload("res://addons/d_logger/constants.gd")


# ------------- [Constructor] -------------
func test_init() -> void:
	var node := _NODE.new()
	assert_object(node).is_not_null()
	node.free()


func test_is_node() -> void:
	var node := _NODE.new()
	assert_bool(node is Node).is_true()
	node.free()


func test_extends_node_base() -> void:
	var node := _NODE.new()
	assert_bool(node is _NODE_BASE).is_true()
	node.free()


# ------------- [_ready] -------------
func test_ready_creates_logger() -> void:
	var node := _NODE.new()
	add_child(node)
	await get_tree().process_frame
	var logger := node.get_logger()
	assert_object(logger).is_not_null()
	assert_bool(logger is _CLASS).is_true()
	node.free()


func test_ready_creates_logger_with_init_param() -> void:
	var node := _NODE.new()
	var param := _INIT_PARAM.new("CUSTOM", -1, false, "")
	node._init_param = param
	add_child(node)
	await get_tree().process_frame
	assert_object(node.get_logger()).is_not_null()
	node.free()


func test_get_logger_after_ready() -> void:
	var node := _NODE.new()
	add_child(node)
	await get_tree().process_frame
	var logger := node.get_logger()
	assert_object(logger).is_not_null()
	assert_bool(logger is _CLASS).is_true()
	node.free()


# ------------- [_enter_tree / _exit_tree] -------------
func test_enter_tree_connects_settings_changed() -> void:
	var node := _NODE.new()
	add_child(node)
	var connected := ProjectSettings.settings_changed.is_connected(
		node._on_settings_changed
	)
	assert_bool(connected).is_true()
	node.free()


func test_exit_tree_disconnects_settings_changed() -> void:
	var node := _NODE.new()
	add_child(node)
	remove_child(node)
	var connected := ProjectSettings.settings_changed.is_connected(
		node._on_settings_changed
	)
	assert_bool(connected).is_false()
	node.free()


# ------------- [_create_logger_from_settings] -------------
func test_create_logger_from_settings_default() -> void:
	var param := _INIT_PARAM.new()
	var logger := _NODE._create_logger_from_settings(param)
	assert_object(logger).is_not_null()
	assert_bool(logger is _CLASS).is_true()


func test_create_logger_from_settings_with_prefix() -> void:
	var param := _INIT_PARAM.new("MY_PREFIX")
	var logger := _NODE._create_logger_from_settings(param)
	assert_str(logger.get_prefix()).is_equal("MY_PREFIX")


func test_create_logger_from_settings_with_level() -> void:
	var param := _INIT_PARAM.new("", _CONST.LogLevel.WARN)
	var logger := _NODE._create_logger_from_settings(param)
	assert_int(logger.get_min_level()).is_equal(_CONST.LogLevel.WARN)


func test_create_logger_from_settings_with_console() -> void:
	var param := _INIT_PARAM.new("", -1, false, "")
	var logger := _NODE._create_logger_from_settings(param)
	assert_bool(logger._has_console_override).is_true()
	assert_bool(logger._override_console_enabled).is_false()


func test_create_logger_from_settings_with_file_path() -> void:
	var param := _INIT_PARAM.new("", -1, null, "user://test.log")
	var logger := _NODE._create_logger_from_settings(param)
	assert_str(logger._override_file_path).is_equal("user://test.log")
