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
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> void:
	print_rich("[color=gray]%s[/color]" % [_C.format_log(msg, category, "DEBUG", context, prefix)])


## from [ILogger]
func info(
	msg: String,
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> void:
	print_rich(
		"[b][color=cyan]%s[/color][/b]" % [_C.format_log(msg, category, "INFO", context, prefix)]
	)


## from [ILogger]
func warn(
	msg: String,
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> void:
	var header: String = _C.format_log(msg, category, "WARN", context, prefix)
	print_rich("[b][color=yellow]%s[/color][/b]" % [header])
	push_warning(header)


## from [ILogger]
func error(
	msg: String,
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> void:
	var header: String = _C.format_log(msg, category, "ERROR", context, prefix)
	print_rich("[b][color=red]%s[/color][/b]" % [header])
	push_error(header)
