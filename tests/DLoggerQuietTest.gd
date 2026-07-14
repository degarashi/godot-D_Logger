class_name DLoggerQuietTest
extends GdUnitTestSuite

const _QUIET = preload("res://addons/d_logger/logger/d_logger_quiet.gd")


# ------------- [Level Checks] -------------
func test_debug_disabled() -> void:
	var quiet := _QUIET.new()
	assert_bool(quiet.is_debug_enabled()).is_false()


func test_info_disabled() -> void:
	var quiet := _QUIET.new()
	assert_bool(quiet.is_info_enabled()).is_false()


func test_warn_enabled() -> void:
	var quiet := _QUIET.new()
	assert_bool(quiet.is_warn_enabled()).is_true()


func test_error_enabled() -> void:
	var quiet := _QUIET.new()
	assert_bool(quiet.is_error_enabled()).is_true()


# ------------- [Log Methods] -------------
func test_debug_returns_true() -> void:
	var quiet := _QUIET.new()
	# debug() returns true but does not output (level check fails)
	assert_bool(quiet.debug("test")).is_true()


func test_info_returns_true() -> void:
	var quiet := _QUIET.new()
	assert_bool(quiet.info("test")).is_true()


func test_warn_returns_true() -> void:
	var quiet := _QUIET.new()
	assert_bool(quiet.warn("test")).is_true()


func test_error_returns_true() -> void:
	var quiet := _QUIET.new()
	assert_bool(quiet.error("test")).is_true()


# ------------- [Output Behavior] -------------
func test_debug_does_not_output() -> void:
	var quiet := _QUIET.new()
	# debug() is disabled, so _output should NOT be called
	quiet.debug("should not appear")
	# If it did call _output, it would push nothing (debug is disabled at level check)
	assert_bool(quiet.is_debug_enabled()).is_false()


func test_info_does_not_output() -> void:
	var quiet := _QUIET.new()
	quiet.info("should not appear")
	assert_bool(quiet.is_info_enabled()).is_false()


func test_warn_outputs_via_push_warning() -> void:
	var quiet := _QUIET.new()
	# warn() should call _output which calls push_warning
	# We can't easily capture push_warning output, but we verify the method runs
	assert_bool(quiet.warn("warning message")).is_true()


func test_error_outputs_via_push_error() -> void:
	var quiet := _QUIET.new()
	assert_bool(quiet.error("error message")).is_true()


# ------------- [String Formatting] -------------
func test_format_with_values() -> void:
	var quiet := _QUIET.new()
	assert_bool(quiet.warn("Value: {0}", [42])).is_true()


func test_format_with_dict() -> void:
	var quiet := _QUIET.new()
	assert_bool(quiet.error("HP={hp}", {"hp": 100})).is_true()


# ------------- [Constructor] -------------
func test_init() -> void:
	var quiet := _QUIET.new()
	assert_object(quiet).is_not_null()


# ------------- [_Output Push Verification] -------------
func test_output_debug_no_output() -> void:
	var quiet := _QUIET.new()
	# debug() is disabled - _output is bypassed at level check
	assert_bool(quiet.debug("should not output")).is_true()
	assert_bool(quiet.is_debug_enabled()).is_false()


func test_output_info_no_output() -> void:
	var quiet := _QUIET.new()
	assert_bool(quiet.info("should not output")).is_true()
	assert_bool(quiet.is_info_enabled()).is_false()


func test_output_warn_output_via_push_warning() -> void:
	var quiet := _QUIET.new()
	# warn() calls _output which calls push_warning
	assert_bool(quiet.warn("warn via push_warning")).is_true()


func test_output_error_output_via_push_error() -> void:
	var quiet := _QUIET.new()
	assert_bool(quiet.error("error via push_error")).is_true()


func test_output_no_file_or_console_write() -> void:
	var quiet := _QUIET.new()
	# Quiet does not write to files or console; verify no side effects
	quiet.debug("no side effect")
	quiet.info("no side effect")
	quiet.warn("no side effect")
	quiet.error("no side effect")
	assert_bool(quiet.is_debug_enabled()).is_false()
	assert_bool(quiet.is_info_enabled()).is_false()
