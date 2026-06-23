@tool
extends RefCounted


# ------------- [Public Method] -------------
func _init() -> void:
	assert(DLoggerFunc.is_logger(self))


func is_debug_enabled() -> bool:
	return false


func is_info_enabled() -> bool:
	return false


func is_warn_enabled() -> bool:
	return true


func is_error_enabled() -> bool:
	return true


func debug(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_prefix: String = "",
	_p_caller_info: Variant = null
) -> bool:
	return true


func info(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_prefix: String = "",
	_p_caller_info: Variant = null
) -> bool:
	return true


func warn(
	msg: String,
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null
) -> bool:
	push_warning(DLoggerFunc.format_log(msg, category, "WARN", context, prefix, p_caller_info))
	return true


func error(
	msg: String,
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null
) -> bool:
	push_error(DLoggerFunc.format_log(msg, category, "ERROR", context, prefix, p_caller_info))
	return true
