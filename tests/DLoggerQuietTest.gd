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
class QuietSpy:
	extends _QUIET

	var output_levels: Array[String] = []

	func _output(
		msg: String,
		values: Variant,
		category: String,
		context: Object,
		prefix: String,
		p_caller_info: Variant,
		level: String
	) -> void:
		output_levels.append(level)


func test_debug_does_not_output() -> void:
	var spy := QuietSpy.new()
	spy.debug("should not appear")
	# debug() is disabled at the level check, so _output must not be called
	assert_array(spy.output_levels).is_empty()


func test_info_does_not_output() -> void:
	var spy := QuietSpy.new()
	spy.info("should not appear")
	assert_array(spy.output_levels).is_empty()


func test_warn_outputs_via_push_warning() -> void:
	var spy := QuietSpy.new()
	spy.warn("warning message")
	assert_array(spy.output_levels).is_equal(["WARN"])


func test_error_outputs_via_push_error() -> void:
	var spy := QuietSpy.new()
	spy.error("error message")
	assert_array(spy.output_levels).is_equal(["ERROR"])


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


# ------------- [_Output Verification] -------------
func test_output_debug_and_info_suppressed() -> void:
	var spy := QuietSpy.new()
	spy.debug("should not output")
	spy.info("should not output")
	assert_array(spy.output_levels).is_empty()


func test_output_warn_and_error_forwarded() -> void:
	var spy := QuietSpy.new()
	spy.warn("warn via push_warning")
	spy.error("error via push_error")
	assert_array(spy.output_levels).is_equal(["WARN", "ERROR"])
