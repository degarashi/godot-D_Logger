@tool
extends RefCounted

# ------------- [Public Variable] -------------
var _list: Array[RefCounted] = []


# ------------- [Public Method] -------------
func _init() -> void:
	assert(DLoggerFunc.is_logger(self))


func clear() -> void:
	_list.clear()


func add(logger: RefCounted) -> void:
	assert(logger != null, "logger must not be null")
	_list.append(logger)


func is_empty() -> bool:
	return _list.is_empty()


func is_debug_enabled() -> bool:
	return true


func is_info_enabled() -> bool:
	return true


func is_warn_enabled() -> bool:
	return true


func is_error_enabled() -> bool:
	return true


func debug(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null
) -> bool:
	for l in _list:
		l.debug(msg, values, category, context, prefix, p_caller_info)
	return true


func info(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null
) -> bool:
	for l in _list:
		l.info(msg, values, category, context, prefix, p_caller_info)
	return true


func warn(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null
) -> bool:
	for l in _list:
		l.warn(msg, values, category, context, prefix, p_caller_info)
	return true


func error(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = "",
	p_caller_info: Variant = null
) -> bool:
	for l in _list:
		l.error(msg, values, category, context, prefix, p_caller_info)
	return true
