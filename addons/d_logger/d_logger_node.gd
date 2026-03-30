@tool
class_name DLoggerNode
extends DLoggerNodeBase

# ------------- [Exports] -------------
@export var _init_param: DLoggerInitParam


# ------------- [Callbacks] -------------
func _enter_tree() -> void:
	if not ProjectSettings.settings_changed.is_connected(_on_settings_changed):
		ProjectSettings.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()


func _ready() -> void:
	if not _init_param:
		_init_param = DLoggerInitParam.new()
	_create_logger()


# ------------- [Private Method] -------------
func _on_settings_changed() -> void:
	if _logger:
		_logger.setup_logger()


func _create_logger() -> void:
	_logger = DLoggerClass.new(
		_init_param.prefix_override if not _init_param.prefix_override.is_empty() else null,
		_init_param.min_level_override,
		_init_param.console_enabled_override,
		_init_param.file_path_override
	)
