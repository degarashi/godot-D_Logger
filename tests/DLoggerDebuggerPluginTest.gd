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


# ------------- [_forward_to_panel] -------------
class FakePanel:
	extends Control

	var received: Array[Dictionary] = []

	func add_log(log_data: Dictionary) -> void:
		received.append(log_data)


func test_forward_to_panel_forwards_log() -> void:
	var panel := FakePanel.new()
	(
		assert_bool(_DEBUGGER._forward_to_panel(panel, {"message": "hello"}))
		. is_true()
	)
	# Forwarded via call_deferred, so it lands on the next frame
	assert_int(panel.received.size()).is_equal(0)
	await get_tree().process_frame
	assert_int(panel.received.size()).is_equal(1)
	assert_str(panel.received[0].get("message", "")).is_equal("hello")
	panel.free()


func test_forward_to_panel_rejects_panel_without_add_log() -> void:
	var panel := Control.new()
	(
		assert_bool(_DEBUGGER._forward_to_panel(panel, {"message": "hello"}))
		. is_false()
	)
	panel.free()


func test_forward_to_panel_without_panel_returns_false() -> void:
	(
		assert_bool(_DEBUGGER._forward_to_panel(null, {"message": "hello"}))
		. is_false()
	)
