@tool
extends RefCounted

# ------------- [Public Variable] -------------
var _list: Array[RefCounted] = []


# ------------- [Public Method] -------------
func clear() -> void:
	_list.clear()


func add(logger: RefCounted) -> void:
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
	prefix: String = ""
) -> void:
	for l: Object in _list:
		l.debug(msg, values, category, context, prefix)


func info(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> void:
	for l: Object in _list:
		l.info(msg, values, category, context, prefix)


func warn(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> void:
	for l: Object in _list:
		l.warn(msg, values, category, context, prefix)


func error(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> void:
	for l: Object in _list:
		l.error(msg, values, category, context, prefix)
