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

		# Constructing the string
		var formatted_msg: String = "[{0}][{1}] {2} {3} - [{4}] {5}".format(
			[
				"Game",
				log_data.get("prefix", ""),
				log_data.get("context_str", ""),
				log_data.get("category", ""),
				log_data.get("level", ""),
				log_data.get("message", "")
			]
		)

		# Color coding with BBCode
		var bbcode_msg: String = formatted_msg
		var level: String = log_data.get("level", "DEBUG")
		match level:
			"DEBUG":
				bbcode_msg = "[color=gray]{0}[/color]".format([formatted_msg])
			"INFO":
				bbcode_msg = "[b][color=cyan]{0}[/color][/b]".format([formatted_msg])
			"WARN":
				bbcode_msg = "[b][color=yellow]{0}[/color][/b]".format([formatted_msg])
			"ERROR":
				bbcode_msg = "[b][color=red]{0}[/color][/b]".format([formatted_msg])

		# Safely call the UI on the main thread
		if _panel and _panel.has_method("append_log"):
			_panel.call_deferred("append_log", bbcode_msg)

		return true  # Tells the engine that the message was processed successfully

	return false  # Not a message this plugin should handle
