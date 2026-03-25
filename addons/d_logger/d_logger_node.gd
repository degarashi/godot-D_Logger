@tool
class_name DLoggerNode
extends Node

## The underlying RefCounted logger instance
var logger: DLoggerClass

@export var prefix_override: String = ""
@export var min_level_override: int = -1
@export var console_enabled_override: bool = true
@export var file_path_override: String = ""


func _init() -> void:
	# We initialize it here, but can be updated via exports or setup
	_create_logger()


func _enter_tree() -> void:
	if not ProjectSettings.settings_changed.is_connected(_on_settings_changed):
		ProjectSettings.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()


func _on_settings_changed() -> void:
	if logger:
		logger.setup_logger()


func _create_logger() -> void:
	logger = DLoggerClass.new(
		prefix_override if not prefix_override.is_empty() else null,
		min_level_override,
		console_enabled_override,
		file_path_override
	)


# ------------- [Forwarding Methods] -------------
# These allow using the node directly as a logger if needed


func debug(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	return logger.debug(msg, v, cat, ctx, p)


func info(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	return logger.info(msg, v, cat, ctx, p)


func warn(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	return logger.warn(msg, v, cat, ctx, p)


func error(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	return logger.error(msg, v, cat, ctx, p)
