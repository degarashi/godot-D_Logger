class_name DLoggerClassTest
extends GdUnitTestSuite

const _CLASS = preload("res://addons/d_logger/d_logger.gd")
const _CONST = preload("res://addons/d_logger/constants.gd")


# ------------- [Constructor] -------------
func test_init_default() -> void:
	var logger := _CLASS.new()
	assert_object(logger).is_not_null()
	assert_bool(logger._initialized).is_true()


func test_init_custom_prefix() -> void:
	var logger := _CLASS.new("MY_PREFIX")
	assert_str(logger.get_prefix()).is_equal("MY_PREFIX")


func test_init_custom_level() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.WARN)
	assert_int(logger._min_level).is_equal(_CONST.LogLevel.WARN)


func test_init_console_override() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG, false)
	assert_bool(logger._has_console_override).is_true()
	assert_bool(logger._override_console_enabled).is_false()


func test_init_file_path() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG, null, "user://test.log")
	assert_str(logger._override_file_path).is_equal("user://test.log")


# ------------- [get_prefix] -------------
func test_get_prefix_override() -> void:
	var logger := _CLASS.new("OVERRIDE_PREFIX")
	assert_str(logger.get_prefix()).is_equal("OVERRIDE_PREFIX")


func test_get_prefix_from_settings() -> void:
	ProjectSettings.set_setting(_CONST.SETTING_PREFIX, "SETTINGS_PREFIX")
	var logger := _CLASS.new()
	# Logger reads from ProjectSettings when no override
	assert_str(logger.get_prefix()).is_equal("SETTINGS_PREFIX")
	# Cleanup
	ProjectSettings.set_setting(_CONST.SETTING_PREFIX, _CONST.DEFAULT_PREFIX)


# ------------- [get_min_level] -------------
func test_get_min_level_override() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.ERROR)
	assert_int(logger.get_min_level()).is_equal(_CONST.LogLevel.ERROR)


func test_get_min_level_not_specified_uses_settings() -> void:
	ProjectSettings.set_setting(_CONST.SETTING_MIN_LEVEL, _CONST.LogLevel.WARN)
	var logger := _CLASS.new()
	assert_int(logger.get_min_level()).is_equal(_CONST.LogLevel.WARN)
	# Cleanup
	ProjectSettings.set_setting(_CONST.SETTING_MIN_LEVEL, 0)


# ------------- [Level Checks] -------------
func test_is_debug_enabled_default() -> void:
	var logger := _CLASS.new()
	assert_bool(logger.is_debug_enabled()).is_true()


func test_is_info_enabled_default() -> void:
	var logger := _CLASS.new()
	assert_bool(logger.is_info_enabled()).is_true()


func test_is_warn_enabled_default() -> void:
	var logger := _CLASS.new()
	assert_bool(logger.is_warn_enabled()).is_true()


func test_is_error_enabled_default() -> void:
	var logger := _CLASS.new()
	assert_bool(logger.is_error_enabled()).is_true()


func test_is_debug_enabled_when_level_is_info() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.INFO)
	assert_bool(logger.is_debug_enabled()).is_false()


func test_is_info_enabled_when_level_is_warn() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.WARN)
	assert_bool(logger.is_info_enabled()).is_false()


func test_is_warn_enabled_when_level_is_error() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.ERROR)
	assert_bool(logger.is_warn_enabled()).is_false()


func test_is_error_enabled_when_level_is_error() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.ERROR)
	assert_bool(logger.is_error_enabled()).is_true()


# ------------- [Log Methods Return True] -------------
func test_debug_returns_true() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(logger.debug("test")).is_true()


func test_info_returns_true() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(logger.info("test")).is_true()


func test_warn_returns_true() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(logger.warn("test")).is_true()


func test_error_returns_true() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(logger.error("test")).is_true()


# ------------- [Level Filtering] -------------
func test_debug_not_dispatched_when_disabled() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.INFO)
	# debug() should still return true even if level is disabled
	assert_bool(logger.debug("should not dispatch")).is_true()


func test_info_not_dispatched_when_level_is_warn() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.WARN)
	assert_bool(logger.info("should not dispatch")).is_true()


func test_warn_not_dispatched_when_level_is_error() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.ERROR)
	assert_bool(logger.warn("should not dispatch")).is_true()


func test_error_dispatched_when_level_is_error() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.ERROR)
	# error() should dispatch even when level is ERROR
	assert_bool(logger.error("should dispatch")).is_true()


# ------------- [String Formatting] -------------
func test_format_with_array() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	# Should not crash, formats {0} with array values
	assert_bool(logger.info("Value: {0}", [42])).is_true()


func test_format_with_dict() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	# Should not crash, formats {hp} with dict
	assert_bool(logger.info("HP={hp}", {"hp": 100})).is_true()


func test_format_with_single_value() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	# Should not crash, wraps single value in array for format
	assert_bool(logger.info("Value: {0}", 42)).is_true()


func test_format_with_empty_values() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	# Empty array should not crash
	assert_bool(logger.info("No values")).is_true()


# ------------- [Category & Context] -------------
func test_with_category() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(logger.info("msg", [], "System")).is_true()


func test_with_context() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	var node := Node.new()
	assert_bool(logger.info("msg", [], "", node)).is_true()
	node.free()


func test_with_prefix_override() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(logger.info("msg", [], "", null, "CUSTOM")).is_true()


# ------------- [Setup Logger] -------------
func test_setup_logger_clears_dispatcher() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(logger._dispatcher.is_empty()).is_false()
	# setup_logger should rebuild
	logger.setup_logger()
	# After setup, dispatcher should have at least the quiet fallback
	assert_int(logger._dispatcher._list.size()).is_greater(0)
