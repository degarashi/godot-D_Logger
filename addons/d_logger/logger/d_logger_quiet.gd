@tool
extends RefCounted

# ------------- [Constants] -------------
const _C = preload("uid://cwfe01280qmo7")


# ------------- [Public Method] -------------
func is_debug_enabled() -> bool:
	return false


func is_info_enabled() -> bool:
	return false


func is_warn_enabled() -> bool:
	return true


func is_error_enabled() -> bool:
	return true


func debug(
	_m: String, _v: Variant = [], _cat: String = "", _ctx: Object = null, _p: String = ""
) -> void:
	pass


func info(
	_m: String, _v: Variant = [], _cat: String = "", _ctx: Object = null, _p: String = ""
) -> void:
	pass


func warn(
	msg: String, _v: Variant = [], cat: String = "", ctx: Object = null, pref: String = ""
) -> void:
	push_warning(_C.format_log(msg, cat, "WARN", ctx, pref))


func error(
	msg: String, _v: Variant = [], cat: String = "", ctx: Object = null, pref: String = ""
) -> void:
	push_error(_C.format_log(msg, cat, "ERROR", ctx, pref))
