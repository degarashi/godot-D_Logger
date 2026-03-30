@tool
class_name DLoggerNode
extends DLoggerNodeBase

# ------------- [Exports] -------------
@export var prefix_override: String = ""
@export var min_level_override := _C.LogLevel.NOT_SPECIFIED
@export var console_enabled_override: bool = true
@export var file_path_override: String = ""


# ------------- [Callbacks] -------------
func _enter_tree() -> void:
	if not ProjectSettings.settings_changed.is_connected(_on_settings_changed):
		ProjectSettings.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()


func _ready() -> void:
	_create_logger()


# ------------- [Private Method] -------------
func _on_settings_changed() -> void:
	if _logger:
		_logger.setup_logger()


func _create_logger() -> void:
	_logger = DLoggerClass.new(
		prefix_override if not prefix_override.is_empty() else null,
		min_level_override,
		console_enabled_override,
		file_path_override
	)
