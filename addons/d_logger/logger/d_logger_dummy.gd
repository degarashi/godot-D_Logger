@tool
extends RefCounted


# ------------- [Public Static Method] -------------
static func implements_list() -> Array[Script]:
	return [ILogger] as Array[Script]


# ------------- [Public Method] -------------
## from [ILogger]
func is_debug_enabled() -> bool:
	return false


## from [ILogger]
func is_info_enabled() -> bool:
	return false


## from [ILogger]
func is_warn_enabled() -> bool:
	return false


## from [ILogger]
func is_error_enabled() -> bool:
	return false


## from [ILogger]
func debug(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_prefix: String = ""
) -> void:
	pass


## from [ILogger]
func info(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_prefix: String = ""
) -> void:
	pass


## from [ILogger]
func warn(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_prefix: String = ""
) -> void:
	pass


## from [ILogger]
func error(
	_msg: String,
	_values: Variant = [],
	_category: String = "",
	_context: Object = null,
	_prefix: String = ""
) -> void:
	pass
