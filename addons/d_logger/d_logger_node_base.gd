@tool
class_name DLoggerNodeBase
extends Node

# ------------- [Public Variable] -------------
## The underlying RefCounted _logger instance
var _logger: DLoggerClass


# ------------- [Callbacks] -------------
func _init() -> void:
	assert(DLoggerFunc.is_logger(self))


# ------------- [Public Method] -------------
func get_logger() -> DLoggerClass:
	return _logger


# ------------- [Forwarding Methods] -------------
# These allow using the node directly as a _logger if needed.
# A missing _logger (before _ready) still returns true: the log calls
# double as assert() conditions, and failing an assert for "logger not
# ready yet" would be worse than dropping one early log line.
# The trailing timestamp arguments mirror DLoggerBase: callers normally
# omit them and the dispatcher samples the clock instead.
func is_debug_enabled() -> bool:
	return _logger.is_debug_enabled() if _logger else false


func is_info_enabled() -> bool:
	return _logger.is_info_enabled() if _logger else false


func is_warn_enabled() -> bool:
	return _logger.is_warn_enabled() if _logger else false


func is_error_enabled() -> bool:
	return _logger.is_error_enabled() if _logger else false


func debug(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> bool:
	return (
		_logger.debug(msg, v, cat, ctx, p, p_caller_info, p_seconds, p_frames)
		if _logger
		else true
	)


func info(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> bool:
	return (
		_logger.info(msg, v, cat, ctx, p, p_caller_info, p_seconds, p_frames)
		if _logger
		else true
	)


func warn(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> bool:
	return (
		_logger.warn(msg, v, cat, ctx, p, p_caller_info, p_seconds, p_frames)
		if _logger
		else true
	)


func error(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> bool:
	return (
		_logger.error(msg, v, cat, ctx, p, p_caller_info, p_seconds, p_frames)
		if _logger
		else true
	)


func benchmark(
	name: String,
	callable: Callable,
	spike_threshold_ms: float = DLoggerClass.DEFAULT_SPIKE_THRESHOLD_MS
) -> Variant:
	return (
		_logger.benchmark(name, callable, spike_threshold_ms)
		if _logger
		else null
	)
