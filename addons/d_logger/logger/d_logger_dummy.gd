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
	return false


func is_error_enabled() -> bool:
	return false


func debug(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_prefix: String = ""
) -> bool:
	return true


func info(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_prefix: String = ""
) -> bool:
	return true


func warn(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_prefix: String = ""
) -> bool:
	return true


func error(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_prefix: String = ""
) -> bool:
	return true
