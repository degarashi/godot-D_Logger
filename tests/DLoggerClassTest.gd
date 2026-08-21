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
	var logger := _CLASS.new(
		"TEST", _CONST.LogLevel.DEBUG, null, "user://test.log"
	)
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


func test_format_with_mismatched_type_still_dispatches() -> void:
	# A Dictionary passed for a positional {0} placeholder leaves the
	# placeholder unresolved. This must not crash; the raw message is
	# logged and a warning is emitted (detection covered by
	# DLoggerFuncTest.has_unresolved_placeholder).
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(logger.info("Value: {0}", {"hp": 100})).is_true()


func test_format_with_mismatched_type_array_for_named() -> void:
	# An Array passed for a named {name} placeholder must not crash.
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	assert_bool(logger.info("HP={hp}", [100])).is_true()


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


# ------------- [Dispatch-Level Formatting] -------------
func test_dispatch_debug_formatting() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG, true)
	# DLoggerFull spy receives formatted message via dispatcher
	assert_bool(logger.debug("Value: {0}", [42])).is_true()


func test_dispatch_info_formatting() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG, true)
	assert_bool(logger.info("HP={hp}", {"hp": 100})).is_true()


func test_dispatch_warn_formatting() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG, true)
	assert_bool(logger.warn("Warning: {0}", ["low memory"])).is_true()


func test_dispatch_error_formatting_with_pause() -> void:
	ProjectSettings.set_setting(_CONST.SETTING_PAUSE_ON_ERROR, true)
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG, true)
	# Should not crash even with pause_on_error enabled
	assert_bool(logger.error("Fatal: {0}", [42])).is_true()
	ProjectSettings.set_setting(_CONST.SETTING_PAUSE_ON_ERROR, false)
	get_tree().paused = false


func test_dispatch_invalid_type_values() -> void:
	var logger := _CLASS.new("TEST", _CONST.LogLevel.DEBUG)
	# Non-array non-dict non-null value should be wrapped in array
	assert_bool(logger.info("Message: {0}", "string_val")).is_true()


# ------------- [Edge Cases] -------------
func test_unicode_message() -> void:
	var logger := _CLASS.new("UNICODE", _CONST.LogLevel.DEBUG)
	assert_bool(logger.info("日本語メッセージ")).is_true()
	assert_bool(logger.info("Emoji: 🎉🚀💡")).is_true()
	assert_bool(logger.info("Mixed: Hello 世界 {0}", ["🌍"])).is_true()


func test_long_message() -> void:
	var logger := _CLASS.new("LONG", _CONST.LogLevel.DEBUG)
	var long_msg := "A"
	long_msg = long_msg.repeat(10000)
	assert_bool(logger.info(long_msg)).is_true()


func test_null_prefix_constructor() -> void:
	# Passing null (Variant) as first argument - should NOT set prefix override
	var logger: DLoggerClass = _CLASS.new(null)
	assert_bool(logger._has_prefix_override).is_false()
	assert_bool(logger._initialized).is_true()


func test_format_with_special_chars() -> void:
	var logger := _CLASS.new("SPECIAL", _CONST.LogLevel.DEBUG)
	# Message with braces that are not placeholders
	assert_bool(logger.info("Dictionary {key: value}")).is_true()
	assert_bool(logger.info("Curly {braces} in text")).is_true()


func test_dispatch_pause_on_error_disabled() -> void:
	var prev_pause = ProjectSettings.get_setting(
		_CONST.SETTING_PAUSE_ON_ERROR, false
	)
	ProjectSettings.set_setting(_CONST.SETTING_PAUSE_ON_ERROR, false)
	var logger := _CLASS.new("PAUSE", _CONST.LogLevel.DEBUG)
	# Should not pause when setting is disabled
	assert_bool(logger.error("test error")).is_true()
	assert_bool(get_tree().paused).is_false()
	# Cleanup
	ProjectSettings.set_setting(_CONST.SETTING_PAUSE_ON_ERROR, prev_pause)
	get_tree().paused = false


func test_format_with_empty_dict() -> void:
	var logger := _CLASS.new("EDGE", _CONST.LogLevel.DEBUG)
	# Empty dict as values - should not crash, treat as no formatting
	assert_bool(logger.info("empty dict", {})).is_true()


func test_format_with_empty_array() -> void:
	var logger := _CLASS.new("EDGE", _CONST.LogLevel.DEBUG)
	# Empty array as values - should not crash
	assert_bool(logger.info("empty array", [])).is_true()


func test_format_with_bool_value() -> void:
	var logger := _CLASS.new("EDGE", _CONST.LogLevel.DEBUG)
	# Bool value wrapped in array by _dispatch
	assert_bool(logger.info("bool: {0}", true)).is_true()


func test_format_with_float_value() -> void:
	var logger := _CLASS.new("EDGE", _CONST.LogLevel.DEBUG)
	assert_bool(logger.info("float: {0}", 3.14)).is_true()


func test_null_prefix_second_arg() -> void:
	# null prefix with valid level (the null is Variant)
	var logger: DLoggerClass = _CLASS.new(null, _CONST.LogLevel.ERROR)
	assert_bool(logger._has_prefix_override).is_false()
	assert_int(logger._override_min_level).is_equal(_CONST.LogLevel.ERROR)


# ------------- [benchmark] -------------
class LevelSpy:
	extends DLoggerBase

	var levels: Array[String] = []
	var messages: Array[String] = []

	func _output(
		msg: String,
		values: Variant,
		category: String,
		context: Object,
		prefix: String,
		p_caller_info: Variant,
		level: String
	) -> void:
		levels.append(level)
		messages.append(msg)


func test_benchmark_returns_callable_result() -> void:
	var logger := _CLASS.new()
	var spy := LevelSpy.new()
	logger._dispatcher.add(spy)

	var result: Variant = logger.benchmark(
		"test_call", func() -> int: return 42
	)

	assert_int(result).is_equal(42)
	assert_int(spy.levels.size()).is_equal(1)
	assert_str(spy.levels[0]).is_equal("INFO")
	assert_str(spy.messages[0]).contains("PERF test_call:")


func test_benchmark_spike_logs_warning() -> void:
	var logger := _CLASS.new()
	var spy := LevelSpy.new()
	logger._dispatcher.add(spy)

	logger.benchmark("slow_call", func() -> void: pass, 0.0)

	assert_int(spy.levels.size()).is_equal(1)
	assert_str(spy.levels[0]).is_equal("WARN")
	assert_str(spy.messages[0]).contains("spike")


func test_benchmark_respects_level_checks() -> void:
	var logger := _CLASS.new(null, _CONST.LogLevel.WARN)
	var spy := LevelSpy.new()
	logger._dispatcher.add(spy)

	logger.benchmark("normal_call", func() -> void: pass)
	# INFO is suppressed at WARN minimum level
	assert_int(spy.levels.size()).is_equal(0)

	logger.benchmark("spike_call", func() -> void: pass, 0.0)
	assert_int(spy.levels.size()).is_equal(1)
	assert_str(spy.levels[0]).is_equal("WARN")


func test_benchmark_invalid_callable_returns_null() -> void:
	# Regression: a callable bound to a freed object must not crash
	# benchmark(); it returns null without executing or logging.
	var logger := _CLASS.new()
	var spy := LevelSpy.new()
	logger._dispatcher.add(spy)

	var obj := Node.new()
	var bound: Callable = Callable(obj, "to_string")
	obj.free()
	# After free, the bound callable is invalid
	var result: Variant = logger.benchmark("freed_call", bound)
	assert_object(result).is_null()
	assert_int(spy.levels.size()).is_equal(0)
