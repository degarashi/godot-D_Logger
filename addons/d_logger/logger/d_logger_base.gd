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
func debug(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null
) -> bool:
	if is_debug_enabled():
		_output(msg, values, category, context, prefix, p_caller_info, "DEBUG")
	return true


func info(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null
) -> bool:
	if is_info_enabled():
		_output(msg, values, category, context, prefix, p_caller_info, "INFO")
	return true


func warn(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null
) -> bool:
	if is_warn_enabled():
		_output(msg, values, category, context, prefix, p_caller_info, "WARN")
	return true


func error(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null
) -> bool:
	if is_error_enabled():
		_output(msg, values, category, context, prefix, p_caller_info, "ERROR")
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
	level: String
) -> void:
	pass
