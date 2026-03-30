class_name DLoggerInitParam
extends Resource

# ------------- [Constants] -------------
const _C = preload("uid://cwfe01280qmo7")

# ------------- [Exports] -------------
@export var prefix_override: String = ""
@export var min_level_override := _C.LogLevel.NOT_SPECIFIED
@export var console_enabled_override: bool = true
@export var file_path_override: String = ""


# ------------- [Callbacks] -------------
func _init(
	p_prefix: String = "",
	p_min_level: _C.LogLevel = _C.LogLevel.NOT_SPECIFIED,
	p_console_enabled: bool = true,
	p_file_path: String = ""
) -> void:
	prefix_override = p_prefix
	min_level_override = p_min_level
	console_enabled_override = p_console_enabled
	file_path_override = p_file_path
