@tool

const _C = preload("uid://cwfe01280qmo7")


func debug(msg: String, category: String = "", context: Object = null, prefix: String = "") -> void:
	print_rich("[color=gray]%s[/color]" % [_C.format_log(msg, category, "DEBUG", context, prefix)])


func info(msg: String, category: String = "", context: Object = null, prefix: String = "") -> void:
	print_rich(
		"[b][color=cyan]%s[/color][/b]" % [_C.format_log(msg, category, "INFO", context, prefix)]
	)


func warn(msg: Variant, category: String = "", context: Object = null, prefix: String = "") -> void:
	var header := _C.format_log(msg, category, "WARN", context, prefix)
	print_rich("[b][color=yellow]%s[/color][/b]" % [header])
	push_warning(header)


func error(
	msg: Variant, category: String = "", context: Object = null, prefix: String = ""
) -> void:
	var header := _C.format_log(msg, category, "ERROR", context, prefix)
	print_rich("[b][color=red]%s[/color][/b]" % [header])
	push_error(header)
