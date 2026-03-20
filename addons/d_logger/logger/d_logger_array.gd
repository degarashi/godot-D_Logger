@tool

var _list: Array[RefCounted] = []


func clear() -> void:
	_list.clear()


func add(logger: RefCounted) -> void:
	_list.append(logger)


func is_empty() -> bool:
	return _list.is_empty()


func debug(msg: String, cat: String, ctx: Object, pref: String) -> void:
	for l: Object in _list:
		l.debug(msg, cat, ctx, pref)


func info(msg: String, cat: String, ctx: Object, pref: String) -> void:
	for l: Object in _list:
		l.info(msg, cat, ctx, pref)


func warn(msg: String, cat: String, ctx: Object, pref: String) -> void:
	for l: Object in _list:
		l.warn(msg, cat, ctx, pref)


func error(msg: String, cat: String, ctx: Object, pref: String) -> void:
	for l: Object in _list:
		l.error(msg, cat, ctx, pref)
