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
	assert_bool(logger._has_console_override).is_false()


func test_autoload_default_param_uses_project_settings_for_console() -> void:
	var scene := (
		preload("res://addons/d_logger/d_logger_node.tscn").instantiate()
	)
	var logger := _NODE._create_logger_from_settings(scene._init_param)
	assert_object(scene._init_param.console_enabled_override).is_null()
	assert_bool(logger._has_console_override).is_false()
	scene.free()


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


# ------------- [_on_settings_changed] -------------
func test_on_settings_changed_rebuilds_logger() -> void:
	var node := _NODE.new()
	add_child(node)
	await get_tree().process_frame

	var logger := node.get_logger()
	assert_object(logger).is_not_null()
	assert_bool(logger._initialized).is_true()

	# Call _on_settings_changed to simulate ProjectSettings change
	node._on_settings_changed()

	# Logger should still be the same instance but dispatcher rebuilt
	assert_object(node.get_logger()).is_equal(logger)
	assert_bool(logger._initialized).is_true()

	node.free()


func test_on_settings_changed_with_init_param_rebuilds_settings() -> void:
	var node := _NODE.new()
	var param := _INIT_PARAM.new("PARAM_PREFIX")
	node._init_param = param
	add_child(node)
	await get_tree().process_frame

	assert_object(node.get_logger()).is_not_null()
	assert_str(node.get_logger().get_prefix()).is_equal("PARAM_PREFIX")

	ProjectSettings.set_setting(_CONST.SETTING_MIN_LEVEL, _CONST.LogLevel.ERROR)
	node._on_settings_changed()
	assert_int(node.get_logger().get_min_level()).is_equal(
		_CONST.LogLevel.ERROR
	)
	assert_str(node.get_logger().get_prefix()).is_equal("PARAM_PREFIX")
	assert_bool(node.get_logger().info("test")).is_true()

	ProjectSettings.set_setting(_CONST.SETTING_MIN_LEVEL, _CONST.LogLevel.DEBUG)
	node._on_settings_changed()
	node.free()


func test_on_settings_changed_before_ready_no_crash() -> void:
	var node := _NODE.new()
	# _on_settings_changed should not crash when _logger is null
	node._on_settings_changed()
	assert_object(node._logger).is_null()
	node.free()


func test_on_settings_changed_idempotent() -> void:
	var node := _NODE.new()
	add_child(node)
	await get_tree().process_frame

	var logger := node.get_logger()
	# Call multiple times - should not crash or create issues
	node._on_settings_changed()
	node._on_settings_changed()
	node._on_settings_changed()

	assert_object(node.get_logger()).is_equal(logger)
	assert_bool(node.get_logger().info("idempotent test")).is_true()

	node.free()


# ------------- [Settings Change Filtering] -------------
class RebuildSpy:
	extends _CLASS

	var setup_calls := 0

	func setup_logger() -> void:
		setup_calls += 1


func test_unrelated_setting_change_does_not_rebuild() -> void:
	var node := _NODE.new()
	add_child(node)
	await get_tree().process_frame

	var spy := RebuildSpy.new()
	spy.setup_calls = 0
	node._logger = spy

	# ProjectSettings.settings_changed is emitted deferred and fires for ANY
	# setting change; only d_logger keys may trigger a logger rebuild.
	var prev: Variant = ProjectSettings.get_setting(
		"application/config/name", ""
	)
	ProjectSettings.set_setting("application/config/name", "unrelated change")
	await get_tree().process_frame
	assert_int(spy.setup_calls).is_equal(0)
	ProjectSettings.set_setting("application/config/name", prev)
	node.free()


func test_d_logger_setting_change_rebuilds_once() -> void:
	var node := _NODE.new()
	add_child(node)
	await get_tree().process_frame

	var spy := RebuildSpy.new()
	spy.setup_calls = 0
	node._logger = spy

	var prev: Variant = ProjectSettings.get_setting(
		_CONST.SETTING_MIN_LEVEL, _CONST.LogLevel.DEBUG
	)
	var new_level: int = (
		_CONST.LogLevel.ERROR
		if prev != _CONST.LogLevel.ERROR
		else _CONST.LogLevel.WARN
	)

	ProjectSettings.set_setting(_CONST.SETTING_MIN_LEVEL, new_level)
	# settings_changed is emitted deferred, on the next frame.
	await get_tree().process_frame
	assert_int(spy.setup_calls).is_equal(1)

	# The snapshot is updated after the rebuild, so a subsequent unrelated
	# change must not rebuild again.
	ProjectSettings.set_setting(
		"application/config/name", "unrelated after rebuild"
	)
	await get_tree().process_frame
	assert_int(spy.setup_calls).is_equal(1)

	# Restore previous state (ProjectSettings has no remove_setting in 4.7,
	# so restore by value).
	ProjectSettings.set_setting(_CONST.SETTING_MIN_LEVEL, prev)
	ProjectSettings.set_setting("application/config/name", "")
	node.free()
