@tool
class_name DLoggerNode
extends Node

# ------------- [Constants] -------------
const _C = preload("uid://cwfe01280qmo7")

# ------------- [Exports] -------------
@export var prefix_override: String = ""
@export var min_level_override := _C.LogLevel.NOT_SPECIFIED
@export var console_enabled_override: bool = true
@export var file_path_override: String = ""

# ------------- [Public Variable] -------------
## The underlying RefCounted logger instance
var logger: DLoggerClass


# ------------- [Callbacks] -------------
func _init() -> void:
	assert(DLoggerFunc.is_logger(self))


func _enter_tree() -> void:
	if not ProjectSettings.settings_changed.is_connected(_on_settings_changed):
		ProjectSettings.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()


func _ready() -> void:
	_create_logger()


# ------------- [Private Method] -------------
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
func is_debug_enabled() -> bool:
	return logger.is_debug_enabled()


func is_info_enabled() -> bool:
	return logger.is_info_enabled()


func is_warn_enabled() -> bool:
	return logger.is_warn_enabled()


func is_error_enabled() -> bool:
	return logger.is_error_enabled()


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
