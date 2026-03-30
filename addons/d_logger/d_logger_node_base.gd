@tool
class_name DLoggerNodeBase
extends Node

# ------------- [Public Variable] -------------
## The underlying RefCounted _logger instance
var _logger: Object


# ------------- [Callbacks] -------------
func _init() -> void:
	assert(DLoggerFunc.is_logger(self))


# ------------- [Public Methods] -------------
func get_logger() -> Object:
	return _logger


# ------------- [Forwarding Methods] -------------
# These allow using the node directly as a _logger if needed
func is_debug_enabled() -> bool:
	return _logger.is_debug_enabled()


func is_info_enabled() -> bool:
	return _logger.is_info_enabled()


func is_warn_enabled() -> bool:
	return _logger.is_warn_enabled()


func is_error_enabled() -> bool:
	return _logger.is_error_enabled()


func debug(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	return _logger.debug(msg, v, cat, ctx, p)


func info(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	return _logger.info(msg, v, cat, ctx, p)


func warn(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	return _logger.warn(msg, v, cat, ctx, p)


func error(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	return _logger.error(msg, v, cat, ctx, p)
