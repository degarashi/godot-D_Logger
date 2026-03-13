@tool
extends EditorPlugin

const _C = preload("uid://cwfe01280qmo7")


func _enter_tree() -> void:
	_initialize_settings()
	add_autoload_singleton(_C.AUTOLOAD_NAME, _C.AUTOLOAD_PATH)


func _exit_tree() -> void:
	remove_autoload_singleton(_C.AUTOLOAD_NAME)


func _initialize_settings() -> void:
	# --- Prefix Settings ---
	if not ProjectSettings.has_setting(_C.SETTING_PREFIX):
		ProjectSettings.set_setting(_C.SETTING_PREFIX, _C.DEFAULT_PREFIX)

	ProjectSettings.add_property_info(
		{
			"name": _C.SETTING_PREFIX,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "The prefix label displayed at the beginning of each log."
		}
	)
	ProjectSettings.set_initial_value(_C.SETTING_PREFIX, _C.DEFAULT_PREFIX)

	# --- Enable Console Logging ---
	if not ProjectSettings.has_setting(_C.SETTING_ENABLE):
		ProjectSettings.set_setting(_C.SETTING_ENABLE, true)

	ProjectSettings.add_property_info(
		{
			"name": _C.SETTING_ENABLE,
			"type": TYPE_BOOL,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "Toggle to enable or disable detailed console logging."
		}
	)
	ProjectSettings.set_initial_value(_C.SETTING_ENABLE, true)

	# --- MinLevel ---
	if not ProjectSettings.has_setting(_C.SETTING_MIN_LEVEL):
		ProjectSettings.set_setting(_C.SETTING_MIN_LEVEL, 0)  # Default: DEBUG

	ProjectSettings.add_property_info(
		{
			"name": _C.SETTING_MIN_LEVEL,
			"type": TYPE_INT,
			"hint": PROPERTY_HINT_ENUM,
			"hint_string": "Debug:0,Info:1,Warn:2,Error:3"
		}
	)
	ProjectSettings.set_initial_value(_C.SETTING_MIN_LEVEL, 0)

	# --- Enable File Logging ---
	if not ProjectSettings.has_setting(_C.SETTING_ENABLE_FILE):
		ProjectSettings.set_setting(_C.SETTING_ENABLE_FILE, false)

	ProjectSettings.add_property_info(
		{
			"name": _C.SETTING_ENABLE_FILE,
			"type": TYPE_BOOL,
			"hint": PROPERTY_HINT_NONE,
			"hint_string": "Toggle to enable or disable logging to a file."
		}
	)
	ProjectSettings.set_initial_value(_C.SETTING_ENABLE_FILE, false)

	# --- File Path ---
	if not ProjectSettings.has_setting(_C.SETTING_FILE_PATH):
		ProjectSettings.set_setting(_C.SETTING_FILE_PATH, _C.DEFAULT_FILE_PATH)

	ProjectSettings.add_property_info(
		{
			"name": _C.SETTING_FILE_PATH,
			"type": TYPE_STRING,
			"hint": PROPERTY_HINT_FILE,
			"hint_string": "*.log, *.txt;Log Files"
		}
	)
	ProjectSettings.set_initial_value(_C.SETTING_FILE_PATH, _C.DEFAULT_FILE_PATH)

	# Save changes to project.godot
	ProjectSettings.save()
