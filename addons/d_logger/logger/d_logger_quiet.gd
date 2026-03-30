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
	_m: String, _v: Variant = [], _cat: String = "", _ctx: Object = null, _p: String = ""
) -> bool:
	return true


func info(
	_m: String, _v: Variant = [], _cat: String = "", _ctx: Object = null, _p: String = ""
) -> bool:
	return true


func warn(
	msg: String, _v: Variant = [], cat: String = "", ctx: Object = null, pref: String = ""
) -> bool:
	push_warning(DLoggerFunc.format_log(msg, cat, "WARN", ctx, pref))
	return true


func error(
	msg: String, _v: Variant = [], cat: String = "", ctx: Object = null, pref: String = ""
) -> bool:
	push_error(DLoggerFunc.format_log(msg, cat, "ERROR", ctx, pref))
	return true
