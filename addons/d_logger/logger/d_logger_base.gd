@tool
class_name DLoggerBase
extends RefCounted


# ------------- [Callbacks] -------------
func _init() -> void:
	assert(DLoggerFunc.is_logger(self))


# ------------- [Level Checks - Override as needed] -------------
func is_debug_enabled() -> bool:
	return true


func is_info_enabled() -> bool:
	return true


func is_warn_enabled() -> bool:
	return true


func is_error_enabled() -> bool:
	return true


# ------------- [Log Methods - Template Pattern] -------------
# Time/frame are explicit trailing arguments (computed once per log by
# the dispatcher and threaded through) rather than a static cache, so
# every log carries its own timestamp down the chain. Negative sentinels
# mean "not provided": direct callers fall back to a live reading inside
# DLoggerFunc.format_log().
func debug(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> bool:
	if is_debug_enabled():
		_output(
			msg,
			values,
			category,
			context,
			prefix,
			p_caller_info,
			"DEBUG",
			p_seconds,
			p_frames
		)
	return true


func info(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> bool:
	if is_info_enabled():
		_output(
			msg,
			values,
			category,
			context,
			prefix,
			p_caller_info,
			"INFO",
			p_seconds,
			p_frames
		)
	return true


func warn(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> bool:
	if is_warn_enabled():
		_output(
			msg,
			values,
			category,
			context,
			prefix,
			p_caller_info,
			"WARN",
			p_seconds,
			p_frames
		)
	return true


func error(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> bool:
	if is_error_enabled():
		_output(
			msg,
			values,
			category,
			context,
			prefix,
			p_caller_info,
			"ERROR",
			p_seconds,
			p_frames
		)
	return true


# ------------- [Hook Method - Override in subclasses] -------------
## Override this method to implement custom output behavior.
## @param level One of "DEBUG", "INFO", "WARN", "ERROR"
func _output(
	msg: String,
	values: Variant,
	category: String,
	context: Object,
	prefix: String,
	p_caller_info: Variant,
	level: String,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> void:
	pass
