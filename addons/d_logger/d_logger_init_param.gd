class_name DLoggerInitParam
extends Resource

# ------------- [Exports] -------------
@export var prefix_override: String = ""
@export var min_level_override := DLoggerConstants.LogLevel.NOT_SPECIFIED
@export var console_enabled_override: bool = true
@export var file_path_override: String = ""


# ------------- [Callbacks] -------------
func _init(
	p_prefix: String = "",
	p_min_level: DLoggerConstants.LogLevel = DLoggerConstants.LogLevel.NOT_SPECIFIED,
	p_console_enabled: bool = true,
	p_file_path: String = ""
) -> void:
	prefix_override = p_prefix
	min_level_override = p_min_level
	console_enabled_override = p_console_enabled
	file_path_override = p_file_path
