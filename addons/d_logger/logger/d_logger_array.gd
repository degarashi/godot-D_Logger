@tool
extends RefCounted

# ------------- [Public Variable] -------------
var _list: Array[RefCounted] = []


# ------------- [Public Static Method] -------------
static func implements_list() -> Array[Script]:
	return [ILogger]


# ------------- [Public Method] -------------
func clear() -> void:
	_list.clear()


func add(logger: RefCounted) -> void:
	_list.append(logger)


func is_empty() -> bool:
	return _list.is_empty()


## from [ILogger]
func is_debug_enabled() -> bool:
	return true


## from [ILogger]
func is_info_enabled() -> bool:
	return true


## from [ILogger]
func is_warn_enabled() -> bool:
	return true


## from [ILogger]
func is_error_enabled() -> bool:
	return true


## from [ILogger]
func debug(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> void:
	for l: Object in _list:
		l.debug(msg, values, category, context, prefix)


## from [ILogger]
func info(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> void:
	for l: Object in _list:
		l.info(msg, values, category, context, prefix)


## from [ILogger]
func warn(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> void:
	for l: Object in _list:
		l.warn(msg, values, category, context, prefix)


## from [ILogger]
func error(
	msg: String,
	values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> void:
	for l: Object in _list:
		l.error(msg, values, category, context, prefix)
