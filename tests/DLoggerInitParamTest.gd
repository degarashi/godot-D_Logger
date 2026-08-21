class_name DLoggerInitParamTest
extends GdUnitTestSuite

const _PARAM = preload("res://addons/d_logger/d_logger_init_param.gd")
const _CONST = preload("res://addons/d_logger/constants.gd")


# ------------- [Constructor - Default Values] -------------
func test_init_default() -> void:
	var param := _PARAM.new()
	assert_object(param).is_not_null()
	assert_str(param.prefix_override).is_equal("")
	assert_int(param.min_level_override).is_equal(_CONST.LogLevel.NOT_SPECIFIED)
	assert_object(param.console_enabled_override).is_null()
	assert_str(param.file_path_override).is_equal("")


func test_init_with_prefix() -> void:
	var param := _PARAM.new("MY_PREFIX")
	assert_str(param.prefix_override).is_equal("MY_PREFIX")


func test_init_with_min_level() -> void:
	var param := _PARAM.new("", _CONST.LogLevel.WARN)
	assert_int(param.min_level_override).is_equal(_CONST.LogLevel.WARN)


func test_init_with_console_enabled() -> void:
	var param := _PARAM.new("", _CONST.LogLevel.DEBUG, true)
	assert_bool(param.console_enabled_override).is_true()


func test_init_with_console_disabled() -> void:
	var param := _PARAM.new("", _CONST.LogLevel.DEBUG, false)
	assert_bool(param.console_enabled_override).is_false()


func test_init_with_file_path() -> void:
	var param := _PARAM.new(
		"", _CONST.LogLevel.DEBUG, null, "user://custom.log"
	)
	assert_str(param.file_path_override).is_equal("user://custom.log")


func test_init_with_all_params() -> void:
	var param := _PARAM.new(
		"NETWORK", _CONST.LogLevel.INFO, true, "user://network.log"
	)
	assert_str(param.prefix_override).is_equal("NETWORK")
	assert_int(param.min_level_override).is_equal(_CONST.LogLevel.INFO)
	assert_bool(param.console_enabled_override).is_true()
	assert_str(param.file_path_override).is_equal("user://network.log")


# ------------- [Property Mutation] -------------
func test_prefix_override_mutable() -> void:
	var param := _PARAM.new()
	param.prefix_override = "CHANGED"
	assert_str(param.prefix_override).is_equal("CHANGED")


func test_min_level_override_mutable() -> void:
	var param := _PARAM.new()
	param.min_level_override = _CONST.LogLevel.ERROR
	assert_int(param.min_level_override).is_equal(_CONST.LogLevel.ERROR)


func test_console_enabled_override_mutable() -> void:
	var param := _PARAM.new()
	param.console_enabled_override = true
	assert_bool(param.console_enabled_override).is_true()


func test_file_path_override_mutable() -> void:
	var param := _PARAM.new()
	param.file_path_override = "user://changed.log"
	assert_str(param.file_path_override).is_equal("user://changed.log")


# ------------- [Resource Serialization] -------------
func test_is_resource() -> void:
	var param := _PARAM.new()
	assert_bool(param is Resource)


func test_can_duplicate() -> void:
	var param := _PARAM.new(
		"TEST", _CONST.LogLevel.WARN, true, "user://test.log"
	)
	var duplicate := param.duplicate()
	assert_str(duplicate.prefix_override).is_equal("TEST")
	assert_int(duplicate.min_level_override).is_equal(_CONST.LogLevel.WARN)
	assert_bool(duplicate.console_enabled_override).is_true()
	assert_str(duplicate.file_path_override).is_equal("user://test.log")


func test_duplicate_is_independent() -> void:
	var param := _PARAM.new("ORIGINAL")
	var duplicate := param.duplicate()
	duplicate.prefix_override = "MODIFIED"
	assert_str(param.prefix_override).is_equal("ORIGINAL")
	assert_str(duplicate.prefix_override).is_equal("MODIFIED")


# ------------- [Edge Cases] -------------
func test_empty_prefix_string() -> void:
	var param := _PARAM.new("")
	assert_str(param.prefix_override).is_equal("")


func test_not_specified_level() -> void:
	var param := _PARAM.new()
	assert_int(param.min_level_override).is_equal(_CONST.LogLevel.NOT_SPECIFIED)


func test_console_override_null() -> void:
	var param := _PARAM.new()
	assert_object(param.console_enabled_override).is_null()


func test_empty_file_path() -> void:
	var param := _PARAM.new()
	assert_str(param.file_path_override).is_equal("")
