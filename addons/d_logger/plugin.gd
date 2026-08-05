@tool
extends EditorPlugin

const PANEL_SCENE = preload("uid://c4ge4lhdk2crn")
const DEBUGGER_PLUGIN = preload("uid://1wnkr07kpq7c")


# ------------- [Private Variable] -------------
var _settings_manager: DLoggerSettingsManager = DLoggerSettingsManager.new()
var _panel_instance: Control
var _debugger_instance: EditorDebuggerPlugin
var _autoload_added: bool = false


# ------------- [Callbacks] -------------
func _enter_tree() -> void:
	_settings_manager.initialize(get_editor_interface().get_editor_settings())

	if not ProjectSettings.has_setting("autoload/" + DLoggerConstants.AUTOLOAD_NAME):
		add_autoload_singleton(DLoggerConstants.AUTOLOAD_NAME, DLoggerConstants.AUTOLOAD_PATH)
		_autoload_added = true

	# --- add bottom panel ---
	_panel_instance = PANEL_SCENE.instantiate()
	add_control_to_bottom_panel(_panel_instance, "D-Logger")
	DLoggerClass._editor_panel = _panel_instance

	# --- Registering the debugger plugin ---
	_debugger_instance = DEBUGGER_PLUGIN.new(_panel_instance)
	_debugger_instance.on_session_started.connect(_on_debugger_session_started)
	add_debugger_plugin(_debugger_instance)


func _exit_tree() -> void:
	_settings_manager.shutdown()

	# --- Remove autoload singleton if we added it ---
	if _autoload_added:
		remove_autoload_singleton(DLoggerConstants.AUTOLOAD_NAME)
		_autoload_added = false

	# --- Delete debugger plugin ---
	if _debugger_instance:
		remove_debugger_plugin(_debugger_instance)

	# --- bottom panel ---
	if _panel_instance:
		remove_control_from_bottom_panel(_panel_instance)
		_panel_instance.queue_free()
		DLoggerClass._editor_panel = null


func _on_debugger_session_started() -> void:
	var es := get_editor_interface().get_editor_settings()

	var auto_clear: bool = es.get_setting(DLoggerConstants.EDITOR_SETTING_AUTO_CLEAR_ON_START)
	if _panel_instance:
		if auto_clear:
			_panel_instance.clear_logs()
		else:
			# Guard the deferred call: the panel may have been freed by the
			# time the call runs (editor shutdown racing session start).
			var panel := _panel_instance
			call_deferred(
				func() -> void:
					if is_instance_valid(panel):
						panel._reset_auto_scroll()
			)

	# Show the panel when debug session starts
	var auto_activate: bool = es.get_setting(DLoggerConstants.EDITOR_SETTING_AUTO_ACTIVATE_PANEL)
	if _panel_instance and auto_activate:
		var panel: Control = _panel_instance
		call_deferred(
			func() -> void:
				if is_instance_valid(panel):
					make_bottom_panel_item_visible(panel)
		)
