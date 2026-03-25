@tool
extends RefCounted

# ------------- [Constants] -------------
const _C = preload("uid://cwfe01280qmo7")


# ------------- [Public Method] -------------
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
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> bool:
	print_rich("[color=gray]%s[/color]" % [_C.format_log(msg, category, "DEBUG", context, prefix)])
	return true


func info(
	msg: String,
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> bool:
	print_rich(
		"[b][color=cyan]%s[/color][/b]" % [_C.format_log(msg, category, "INFO", context, prefix)]
	)
	return true


func warn(
	msg: String,
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> bool:
	var header: String = _C.format_log(msg, category, "WARN", context, prefix)
	print_rich("[b][color=yellow]%s[/color][/b]" % [header])
	push_warning(header)
	return true


func error(
	msg: String,
	_values: Variant = [],
	category: String = "",
	context: Object = null,
	prefix: String = ""
) -> bool:
	var header: String = _C.format_log(msg, category, "ERROR", context, prefix)
	print_rich("[b][color=red]%s[/color][/b]" % [header])
	push_error(header)
	return true
