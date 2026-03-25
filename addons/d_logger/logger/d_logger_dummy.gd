@tool
extends RefCounted


# ------------- [Public Method] -------------
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
) -> void:
	pass


func info(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_prefix: String = ""
) -> void:
	pass


func warn(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_prefix: String = ""
) -> void:
	pass


func error(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_prefix: String = ""
) -> void:
	pass
