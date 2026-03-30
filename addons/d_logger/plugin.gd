@tool
extends EditorPlugin

const PANEL_SCENE = preload("res://addons/d_logger/panel/d_logger_panel.tscn")
const DEBUGGER_PLUGIN = preload("uid://1wnkr07kpq7c")
var _panel_instance: Control
var _debugger_instance: EditorDebuggerPlugin


func _enter_tree() -> void:
	_initialize_settings()
	add_autoload_singleton(DLoggerConstants.AUTOLOAD_NAME, DLoggerConstants.AUTOLOAD_PATH)

	# --- add bottom panel ---
	_panel_instance = PANEL_SCENE.instantiate()
	add_control_to_bottom_panel(_panel_instance, "D-Logger")

	# --- Registering the debugger plugin ---
	_debugger_instance = DEBUGGER_PLUGIN.new(_panel_instance)
	add_debugger_plugin(_debugger_instance)


func _exit_tree() -> void:
	if ProjectSettings.has_setting(DLoggerConstants.AUTOLOAD_NAME):
		remove_autoload_singleton(DLoggerConstants.AUTOLOAD_NAME)

	# --- Delete debugger plugin ---
	if _debugger_instance:
		remove_debugger_plugin(_debugger_instance)

	# --- bottom panel ---
	if _panel_instance:
		remove_control_from_bottom_panel(_panel_instance)
		_panel_instance.queue_free()


func _initialize_settings() -> void:
	# --- Prefix Settings ---
	_set_default_setting(DLoggerConstants.SETTING_PREFIX, DLoggerConstants.DEFAULT_PREFIX)
	ProjectSettings.add_property_info(
		{
			"name": DLoggerConstants.SETTING_PREFIX,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "The prefix label displayed at the beginning of each log."
		}
	)

	# --- Enable Console Logging ---
	_set_default_setting(DLoggerConstants.SETTING_ENABLE, true)
	ProjectSettings.add_property_info(
		{
			"name": DLoggerConstants.SETTING_ENABLE,
			"type": TYPE_BOOL,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "Toggle to enable or disable detailed console logging."
		}
	)

	# --- MinLevel ---
	_set_default_setting(DLoggerConstants.SETTING_MIN_LEVEL, 0)  # Default: DEBUG
	ProjectSettings.add_property_info(
		{
			"name": DLoggerConstants.SETTING_MIN_LEVEL,
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Debug:0,Info:1,Warn:2,Error:3"
		}
	)

	# --- Enable File Logging ---
	_set_default_setting(DLoggerConstants.SETTING_ENABLE_FILE, false)
	ProjectSettings.add_property_info(
		{
			"name": DLoggerConstants.SETTING_ENABLE_FILE,
			"type": TYPE_BOOL,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "Toggle to enable or disable logging to a file."
		}
	)

	# --- File Path ---
	_set_default_setting(DLoggerConstants.SETTING_FILE_PATH, DLoggerConstants.DEFAULT_FILE_PATH)
	ProjectSettings.add_property_info(
		{
			"name": DLoggerConstants.SETTING_FILE_PATH,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.log, *.txt;Log Files"
		}
	)


## Helper function to safely set default values
func _set_default_setting(setting_path: String, default_value: Variant) -> void:
	# Set the initial value only if the setting does not exist yet
	if not ProjectSettings.has_setting(setting_path):
		ProjectSettings.set_setting(setting_path, default_value)

	# Define the default value used when clicking the reset button
	ProjectSettings.set_initial_value(setting_path, default_value)
