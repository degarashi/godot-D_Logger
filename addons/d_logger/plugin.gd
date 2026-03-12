@tool
extends EditorPlugin

const SETTING_PREFIX := "debug/d_logger/prefix"
const SETTING_ENABLE := "debug/d_logger/enable_log"
const DEFAULT_PREFIX := "D-Logger"
const AUTOLOAD_NAME := "DLogger"
const AUTOLOAD_PATH := "res://addons/d_logger/d_logger.gd"
const SETTING_MIN_LEVEL := "debug/d_logger/min_log_level"


func _enter_tree() -> void:
	_initialize_settings()
	add_autoload_singleton(AUTOLOAD_NAME, AUTOLOAD_PATH)


func _exit_tree() -> void:
	remove_autoload_singleton(AUTOLOAD_NAME)


func _initialize_settings() -> void:
	# --- Prefix Settings ---
	if not ProjectSettings.has_setting(SETTING_PREFIX):
		ProjectSettings.set_setting(SETTING_PREFIX, DEFAULT_PREFIX)

	ProjectSettings.add_property_info(
		{
			"name": SETTING_PREFIX,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "The prefix label displayed at the beginning of each log."
		}
	)
	ProjectSettings.set_initial_value(SETTING_PREFIX, DEFAULT_PREFIX)

	# --- Enable Settings ---
	if not ProjectSettings.has_setting(SETTING_ENABLE):
		ProjectSettings.set_setting(SETTING_ENABLE, true)

	ProjectSettings.add_property_info(
		{
			"name": SETTING_ENABLE,
			"type": TYPE_BOOL,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "Toggle to enable or disable detailed logging."
		}
	)
	ProjectSettings.set_initial_value(SETTING_ENABLE, true)

	# --- MinLevel ---
	if not ProjectSettings.has_setting(SETTING_MIN_LEVEL):
		ProjectSettings.set_setting(SETTING_MIN_LEVEL, 0)  # Default: DEBUG

	ProjectSettings.add_property_info(
		{
			"name": SETTING_MIN_LEVEL,
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Debug:0,Info:1,Warn:2,Error:3"
		}
	)
	ProjectSettings.set_initial_value(SETTING_MIN_LEVEL, 0)

	# Save changes to project.godot
	ProjectSettings.save()
