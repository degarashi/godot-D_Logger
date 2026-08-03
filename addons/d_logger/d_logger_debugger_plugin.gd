@tool
extends EditorDebuggerPlugin

# ------------- [Signal] -------------
signal on_session_started

# ------------- [Private Variable] -------------
var _panel: Control


# ------------- [Callbacks] -------------
## Tells the engine that this plugin captures communication with the "d_logger" prefix
func _has_capture(prefix: String) -> bool:
	return prefix == "d_logger"


## When data is sent from the game, the engine automatically calls this function
func _capture(message: String, data: Array, _session_id: int) -> bool:
	# Check if it is the channel name sent by this logger
	if not _is_log_capture(message, data):
		return false

	var log_data: Dictionary = data[0]
	_forward_to_panel(_panel, log_data)
	return true  # Tells the engine that the message was processed successfully


## Forwards a log to the panel on the main thread (deferred). Static so the
## forwarding logic is testable without an editor session (EditorDebuggerPlugin
## instances cannot be created outside the editor). Returns true when a panel
## accepted the log.
static func _forward_to_panel(panel: Object, log_data: Dictionary) -> bool:
	if panel and panel.has_method("add_log"):
		panel.call_deferred("add_log", log_data)
		return true
	return false


# ------------- [Private Method] -------------
func _init(panel: Control) -> void:
	_panel = panel


func _setup_session(session_id: int) -> void:
	var session := get_session(session_id)
	session.started.connect(func() -> void: on_session_started.emit())


## Decides whether this plugin handles the given debugger message.
## Static so the decision logic is testable without an editor session.
static func _is_log_capture(message: String, data: Array) -> bool:
	return message == "d_logger:log" and data.size() > 0 and data[0] is Dictionary
