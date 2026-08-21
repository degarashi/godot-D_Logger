@tool
class_name DLoggerNode
extends DLoggerNodeBase

# ------------- [Exports] -------------
@export var _init_param: DLoggerInitParam

# Snapshot of the runtime d_logger ProjectSettings values. ProjectSettings.
# settings_changed fires for ANY setting change (resolution, quality, other
# plugins...), so the logger is rebuilt only when one of these actually
# changed. Otherwise every unrelated set_setting() would rebuild the logger
# chain and append a spurious "=== New Session Started ===" file marker.
var _d_logger_settings_snapshot: Dictionary = {}


# ------------- [Callbacks] -------------
func _enter_tree() -> void:
	_d_logger_settings_snapshot = _collect_d_logger_settings()
	if not ProjectSettings.settings_changed.is_connected(_on_settings_changed):
		ProjectSettings.settings_changed.connect(_on_settings_changed)


func _exit_tree() -> void:
	if ProjectSettings.settings_changed.is_connected(_on_settings_changed):
		ProjectSettings.settings_changed.disconnect(_on_settings_changed)


func _ready() -> void:
	# DLoggerClass._init() calls setup_logger() already; no need to call again.
	_logger = _create_logger_from_settings(
		_init_param if _init_param else DLoggerInitParam.new()
	)


# ------------- [Private Static Method] -------------
static func _create_logger_from_settings(
	param: DLoggerInitParam
) -> DLoggerClass:
	return DLoggerClass.new(
		param.prefix_override if not param.prefix_override.is_empty() else null,
		param.min_level_override,
		param.console_enabled_override,
		param.file_path_override
	)


## Collects the runtime d_logger settings currently present in ProjectSettings.
static func _collect_d_logger_settings() -> Dictionary:
	var result := {}
	for key: String in [
		DLoggerConstants.SETTING_PREFIX,
		DLoggerConstants.SETTING_ENABLE_CONSOLE,
		DLoggerConstants.SETTING_MIN_LEVEL,
		DLoggerConstants.SETTING_ENABLE_FILE,
		DLoggerConstants.SETTING_FILE_PATH,
	]:
		if ProjectSettings.has_setting(key):
			result[key] = ProjectSettings.get_setting(key)
	return result


# ------------- [Private Method] -------------
func _on_settings_changed() -> void:
	var current := _collect_d_logger_settings()
	if current == _d_logger_settings_snapshot:
		return
	_d_logger_settings_snapshot = current
	if _logger:
		_logger.setup_logger()
