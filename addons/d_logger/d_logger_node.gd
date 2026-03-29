@tool
class_name DLoggerNode
extends Node

# ------------- [Constants] -------------
const _CF = preload("uid://c6bg8penols5r")

# ------------- [Exports] -------------
@export var prefix_override: String = ""
@export var min_level_override: int = -1
@export var console_enabled_override: bool = true
@export var file_path_override: String = ""

# ------------- [Public Variable] -------------
## The underlying RefCounted logger instance
var logger: DLoggerClass


# ------------- [Callbacks] -------------
func _init() -> void:
	assert(_CF.is_logger(self))

	# We initialize it here, but can be updated via exports or setup
	_create_logger()


func _enter_tree() -> void:
	if not ProjectSettings.settings_changed.is_connected(_on_settings_changed):
		ProjectSettings.settings_changed.connect(_on_settings_changed)
	_on_settings_changed()


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
