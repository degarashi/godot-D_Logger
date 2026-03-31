@tool
extends EditorDebuggerPlugin

var _panel: Control


func _init(panel: Control) -> void:
	_panel = panel


## Tells the engine that this plugin captures communication with the "d_logger" prefix
func _has_capture(prefix: String) -> bool:
	return prefix == "d_logger"


## When data is sent from the game, the engine automatically calls this function
func _capture(message: String, data: Array, _session_id: int) -> bool:
	# Check if it is the channel name sent by this logger
	if message == "d_logger:log" and data.size() > 0:
		var log_data: Dictionary = data[0]

		# Safely call the UI on the main thread
		if _panel and _panel.has_method("add_log"):
			_panel.call_deferred("add_log", log_data)

		return true  # Tells the engine that the message was processed successfully

	return false  # Not a message this plugin should handle
