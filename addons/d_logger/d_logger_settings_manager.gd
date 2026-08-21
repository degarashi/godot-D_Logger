@tool
class_name DLoggerSettingsManager
extends RefCounted


# ------------- [Settings Entry] -------------
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
var _editor_settings: Object = null

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
	),
	SettingsEntry.new(
		DLoggerConstants.EDITOR_SETTING_PAUSE_ON_ERROR,
		DLoggerConstants.SETTING_PAUSE_ON_ERROR,
		TYPE_BOOL,
		false,
		PROPERTY_HINT_NONE,
		"Automatically pause the game tree when an error is logged."
	)
]


# ------------- [Public Method] -------------
## Registers all settings (editor + project), connects to settings_changed,
## and performs the initial runtime sync.
## `es` is typed as Object so tests can pass a duck-typed stand-in for
## EditorSettings.
func initialize(es: Object) -> void:
	_editor_settings = es

	# Register Settings
	for entry in _settings_entries:
		if entry.is_editor_setting:
			if not es.has_setting(entry.sys_name):
				es.set_setting(entry.sys_name, entry.default_val)
				# Revert baseline is set only when the setting is first
				# created. Re-running it every startup would reset the
				# editor's "Reset to default" point on each launch,
				# discarding the user's previous value as the baseline.
				es.set_initial_value(entry.sys_name, entry.default_val, false)

			# metadata for editor UI
			es.add_property_info(
				{
					"name": entry.sys_name,
					"type": entry.type,
					"hint": entry.prop_hint,
					"hint_string": entry.prop_hint_str
				}
			)
		else:
			# Project Setting
			if not ProjectSettings.has_setting(entry.sys_name):
				ProjectSettings.set_setting(entry.sys_name, entry.default_val)
				# set_initial_value can mark the project as dirty in some
				# cases, so it is only called on first registration — not
				# on every editor startup.
				ProjectSettings.set_initial_value(
					entry.sys_name, entry.default_val
				)

			# metadata for editor UI
			ProjectSettings.add_property_info(
				{
					"name": entry.sys_name,
					"type": entry.type,
					"hint": entry.prop_hint,
					"hint_string": entry.prop_hint_str
				}
			)

	# Connect to settings changed to keep runtime in sync
	if not es.settings_changed.is_connected(_on_settings_changed):
		es.settings_changed.connect(_on_settings_changed)

	# Initial sync (only if needed)
	sync_to_runtime()


## Mirrors editor settings into their ProjectSettings counterparts.
## We don't call ProjectSettings.save() here to avoid polluting project.godot
func sync_to_runtime() -> void:
	if _editor_settings == null:
		return

	for entry in _settings_entries:
		if entry.is_editor_setting and not entry.runtime_name.is_empty():
			var val: Variant = _editor_settings.get_setting(entry.sys_name)
			# Only update ProjectSettings if it changed (to avoid unnecessary settings_changed signals)
			if (
				not ProjectSettings.has_setting(entry.runtime_name)
				or ProjectSettings.get_setting(entry.runtime_name) != val
			):
				ProjectSettings.set_setting(entry.runtime_name, val)


## Disconnects from settings_changed. Safe to call multiple times.
func shutdown() -> void:
	if _editor_settings == null:
		return
	if _editor_settings.settings_changed.is_connected(_on_settings_changed):
		_editor_settings.settings_changed.disconnect(_on_settings_changed)
	_editor_settings = null


# ------------- [Private Method] -------------
func _on_settings_changed() -> void:
	sync_to_runtime()
