@tool
extends RefCounted

# ------------- [Constants] -------------
const _C = preload("uid://cwfe01280qmo7")

# ------------- [Public Static Method] -------------
static func implements_list() -> Array[Script]:
	return [ILogger]


# ------------- [Public Method] -------------
## from [ILogger]
func is_debug_enabled() -> bool:
	return false


## from [ILogger]
func is_info_enabled() -> bool:
	return false


## from [ILogger]
func is_warn_enabled() -> bool:
	return true


## from [ILogger]
func is_error_enabled() -> bool:
	return true


## from [ILogger]
func debug(
	_m: String, _v: Variant = [], _cat: String = "", _ctx: Object = null, _p: String = ""
) -> void:
	pass


## from [ILogger]
func info(
	_m: String, _v: Variant = [], _cat: String = "", _ctx: Object = null, _p: String = ""
) -> void:
	pass


## from [ILogger]
func warn(
	msg: String, _v: Variant = [], cat: String = "", ctx: Object = null, pref: String = ""
) -> void:
	push_warning(_C.format_log(msg, cat, "WARN", ctx, pref))


## from [ILogger]
func error(
	msg: String, _v: Variant = [], cat: String = "", ctx: Object = null, pref: String = ""
) -> void:
	push_error(_C.format_log(msg, cat, "ERROR", ctx, pref))
