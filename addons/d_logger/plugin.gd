@tool
extends EditorPlugin

const PANEL_SCENE = preload("uid://c4ge4lhdk2crn")
const DEBUGGER_PLUGIN = preload("uid://1wnkr07kpq7c")


# ------------- [Defines] -------------
# --- Settings Management ---
class SettingsEntry:
	var sys_name: String
	var runtime_name: String  # If not empty, will sync this value to ProjectSettings
	var type: int
	var default_val: Variant
	var prop_hint: int
	var prop_hint_str: String
	var is_editor_setting: bool

	func _init(
		p_sysname: String,
		p_runtime_name: String,
		p_type: int,
		p_default: Variant,
		p_hint: int = PROPERTY_HINT_NONE,
		p_hint_str: String = "",
		p_is_editor_setting: bool = true
	) -> void:
		sys_name = p_sysname
		runtime_name = p_runtime_name
		type = p_type
		default_val = p_default
		prop_hint = p_hint
		prop_hint_str = p_hint_str
		is_editor_setting = p_is_editor_setting


# ------------- [Private Variable] -------------
var _panel_instance: Control
var _debugger_instance: EditorDebuggerPlugin

var _settings_entries: Array[SettingsEntry] = [
	SettingsEntry.new(
		DLoggerConstants.SETTING_PREFIX,
		"",
		TYPE_STRING,
		DLoggerConstants.DEFAULT_PREFIX,
		PROPERTY_HINT_NONE,
		"The prefix label displayed at the beginning of each log.",
		false  # Project Setting
	),
	SettingsEntry.new(
		DLoggerConstants.EDITOR_SETTING_ENABLE_CONSOLE,
		DLoggerConstants.SETTING_ENABLE_CONSOLE,
		TYPE_BOOL,
		false,
		PROPERTY_HINT_NONE,
		"Toggle to enable or disable detailed console logging."
	),
	SettingsEntry.new(
		DLoggerConstants.EDITOR_SETTING_MIN_LEVEL,
		DLoggerConstants.SETTING_MIN_LEVEL,
		TYPE_INT,
		DLoggerConstants.LogLevel.DEBUG,
		PROPERTY_HINT_ENUM,
		DLoggerConstants.MIN_LEVEL_HINT_STRING
	),
	SettingsEntry.new(
		DLoggerConstants.EDITOR_SETTING_ENABLE_FILE,
		DLoggerConstants.SETTING_ENABLE_FILE,
		TYPE_BOOL,
		false,
		PROPERTY_HINT_NONE,
		"Toggle to enable or disable logging to a file."
	),
	SettingsEntry.new(
		DLoggerConstants.EDITOR_SETTING_FILE_PATH,
		DLoggerConstants.SETTING_FILE_PATH,
		TYPE_STRING,
		DLoggerConstants.DEFAULT_FILE_PATH,
		PROPERTY_HINT_FILE,
		"*.log, *.txt;Log Files"
	),
	SettingsEntry.new(
		DLoggerConstants.EDITOR_SETTING_AUTO_ACTIVATE_PANEL,
		"",
		TYPE_BOOL,
		true,
		PROPERTY_HINT_NONE,
		"Automatically activate the D-Logger panel when a debug session starts."
	),
	SettingsEntry.new(
		DLoggerConstants.EDITOR_SETTING_AUTO_CLEAR_ON_START,
		"",
		TYPE_BOOL,
		true,
		PROPERTY_HINT_NONE,
		"Automatically clear the log panel when a new debug session starts."
	)
]


# ------------- [Callbacks] -------------
func _enter_tree() -> void:
	_initialize_settings()

	if not ProjectSettings.has_setting("autoload/" + DLoggerConstants.AUTOLOAD_NAME):
		add_autoload_singleton(DLoggerConstants.AUTOLOAD_NAME, DLoggerConstants.AUTOLOAD_PATH)

	# --- add bottom panel ---
	_panel_instance = PANEL_SCENE.instantiate()
	add_control_to_bottom_panel(_panel_instance, "D-Logger")

	# --- Registering the debugger plugin ---
	_debugger_instance = DEBUGGER_PLUGIN.new(_panel_instance)
	_debugger_instance.on_session_started.connect(_on_debugger_session_started)
	add_debugger_plugin(_debugger_instance)


func _exit_tree() -> void:
	var es := get_editor_interface().get_editor_settings()
	if es.settings_changed.is_connected(_sync_settings_to_runtime):
		es.settings_changed.disconnect(_sync_settings_to_runtime)

	# --- Delete debugger plugin ---
	if _debugger_instance:
		remove_debugger_plugin(_debugger_instance)

	# --- bottom panel ---
	if _panel_instance:
		remove_control_from_bottom_panel(_panel_instance)
		_panel_instance.queue_free()


# ------------- [Private Method] -------------
func _initialize_settings() -> void:
	var es := get_editor_interface().get_editor_settings()

	# Register Settings
	for entry in _settings_entries:
		if entry.is_editor_setting:
			if not es.has_setting(entry.sys_name):
				es.set_setting(entry.sys_name, entry.default_val)

			# metadata for editor UI
			es.add_property_info(
				{
					"name": entry.sys_name,
					"type": entry.type,
					"hint": entry.prop_hint,
					"hint_string": entry.prop_hint_str
				}
			)
			es.set_initial_value(entry.sys_name, entry.default_val, false)
		else:
			# Project Setting
			if not ProjectSettings.has_setting(entry.sys_name):
				ProjectSettings.set_setting(entry.sys_name, entry.default_val)

			# metadata for editor UI
			ProjectSettings.add_property_info(
				{
					"name": entry.sys_name,
					"type": entry.type,
					"hint": entry.prop_hint,
					"hint_string": entry.prop_hint_str
				}
			)
			# set_initial_value can mark project as dirty in some cases,
			# so we only set it if not already present or if we really need it.
			ProjectSettings.set_initial_value(entry.sys_name, entry.default_val)

	# Connect to settings changed to keep runtime in sync
	if not es.settings_changed.is_connected(_sync_settings_to_runtime):
		es.settings_changed.connect(_sync_settings_to_runtime)

	# Initial sync (only if needed)
	_sync_settings_to_runtime()


func _on_debugger_session_started() -> void:
	var es := get_editor_interface().get_editor_settings()

	var auto_clear: bool = es.get_setting(DLoggerConstants.EDITOR_SETTING_AUTO_CLEAR_ON_START)
	if _panel_instance and auto_clear:
		_panel_instance.clear_logs()

	# Show the panel when debug session starts
	var auto_activate: bool = es.get_setting(DLoggerConstants.EDITOR_SETTING_AUTO_ACTIVATE_PANEL)
	if _panel_instance and auto_activate:
		call_deferred("make_bottom_panel_item_visible", _panel_instance)


func _sync_settings_to_runtime() -> void:
	var es := get_editor_interface().get_editor_settings()

	for entry in _settings_entries:
		if entry.is_editor_setting and not entry.runtime_name.is_empty():
			var val: Variant = es.get_setting(entry.sys_name)
			# Only update ProjectSettings if it changed (to avoid unnecessary settings_changed signals)
			if (
				not ProjectSettings.has_setting(entry.runtime_name)
				or ProjectSettings.get_setting(entry.runtime_name) != val
			):
				ProjectSettings.set_setting(entry.runtime_name, val)

	# We don't call ProjectSettings.save() here to avoid polluting project.godot
