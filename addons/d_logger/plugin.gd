@tool
extends EditorPlugin

const _C = preload("uid://cwfe01280qmo7")


func _enter_tree() -> void:
	_initialize_settings()
	add_autoload_singleton(_C.AUTOLOAD_NAME, _C.AUTOLOAD_PATH)


func _exit_tree() -> void:
	if ProjectSettings.has_setting(_C.AUTOLOAD_NAME):
		remove_autoload_singleton(_C.AUTOLOAD_NAME)


func _initialize_settings() -> void:
	# --- Prefix Settings ---
	_set_default_setting(_C.SETTING_PREFIX, _C.DEFAULT_PREFIX)
	ProjectSettings.add_property_info(
		{
			"name": _C.SETTING_PREFIX,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "The prefix label displayed at the beginning of each log."
		}
	)

	# --- Enable Console Logging ---
	_set_default_setting(_C.SETTING_ENABLE, true)
	ProjectSettings.add_property_info(
		{
			"name": _C.SETTING_ENABLE,
			"type": TYPE_BOOL,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "Toggle to enable or disable detailed console logging."
		}
	)

	# --- MinLevel ---
	_set_default_setting(_C.SETTING_MIN_LEVEL, 0)  # Default: DEBUG
	ProjectSettings.add_property_info(
		{
			"name": _C.SETTING_MIN_LEVEL,
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Debug:0,Info:1,Warn:2,Error:3"
		}
	)

	# --- Enable File Logging ---
	_set_default_setting(_C.SETTING_ENABLE_FILE, false)
	ProjectSettings.add_property_info(
		{
			"name": _C.SETTING_ENABLE_FILE,
			"type": TYPE_BOOL,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "Toggle to enable or disable logging to a file."
		}
	)

	# --- File Path ---
	_set_default_setting(_C.SETTING_FILE_PATH, _C.DEFAULT_FILE_PATH)
	ProjectSettings.add_property_info(
		{
			"name": _C.SETTING_FILE_PATH,
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
