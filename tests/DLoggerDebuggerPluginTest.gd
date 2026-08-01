class_name DLoggerDebuggerPluginTest
extends GdUnitTestSuite

const _DEBUGGER = preload("res://addons/d_logger/d_logger_debugger_plugin.gd")


# ------------- [_is_log_capture] -------------
func test_is_log_capture_accepts_d_logger_message() -> void:
	var data: Array = [{"message": "hello"}]
	assert_bool(_DEBUGGER._is_log_capture("d_logger:log", data)).is_true()


func test_is_log_capture_rejects_other_message_names() -> void:
	var data: Array = [{"message": "hello"}]
	assert_bool(_DEBUGGER._is_log_capture("other:msg", data)).is_false()
	assert_bool(_DEBUGGER._is_log_capture("d_logger", data)).is_false()
	assert_bool(_DEBUGGER._is_log_capture("", data)).is_false()


func test_is_log_capture_rejects_empty_data() -> void:
	var data: Array = []
	assert_bool(_DEBUGGER._is_log_capture("d_logger:log", data)).is_false()


func test_is_log_capture_rejects_non_dictionary_payload() -> void:
	var data: Array = ["plain string"]
	assert_bool(_DEBUGGER._is_log_capture("d_logger:log", data)).is_false()
