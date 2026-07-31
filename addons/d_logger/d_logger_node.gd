@tool
class_name DLoggerNode
extends DLoggerNodeBase

# ------------- [Exports] -------------
@export var _init_param: DLoggerInitParam


# ------------- [Callbacks] -------------
func _enter_tree() -> void:
	if not ProjectSettings.settings_changed.is_connected(_on_settings_changed):
		ProjectSettings.settings_changed.connect(_on_settings_changed)


func _exit_tree() -> void:
	if ProjectSettings.settings_changed.is_connected(_on_settings_changed):
		ProjectSettings.settings_changed.disconnect(_on_settings_changed)


func _ready() -> void:
	# DLoggerClass._init() calls setup_logger() already; no need to call again.
	_logger = _create_logger_from_settings(_init_param if _init_param else DLoggerInitParam.new())


# ------------- [Private Static Method] -------------
static func _create_logger_from_settings(param: DLoggerInitParam) -> DLoggerClass:
	return DLoggerClass.new(
		param.prefix_override if not param.prefix_override.is_empty() else null,
		param.min_level_override,
		param.console_enabled_override,
		param.file_path_override
	)


# ------------- [Private Method] -------------
func _on_settings_changed() -> void:
	if not _init_param and _logger:
		_logger.setup_logger()
