@tool
extends RefCounted

const _CF = preload("uid://c6bg8penols5r")
# ------------- [Public Variable] -------------
var _list: Array[RefCounted] = []


# ------------- [Public Method] -------------
func _init() -> void:
	assert(_CF.is_logger(self))


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
) -> bool:
	for l in _list:
		l.debug(msg, values, category, context, prefix)
	return true


func info(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> bool:
	for l in _list:
		l.info(msg, values, category, context, prefix)
	return true


func warn(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> bool:
	for l in _list:
		l.warn(msg, values, category, context, prefix)
	return true


func error(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> bool:
	for l in _list:
		l.error(msg, values, category, context, prefix)
	return true
