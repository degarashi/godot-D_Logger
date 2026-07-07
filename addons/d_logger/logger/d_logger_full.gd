@tool
extends DLoggerBase


# ------------- [Output] -------------
func _output(
	msg: String,
	values: Variant,
	category: String,
	context: Object,
	prefix: String,
	p_caller_info: Variant,
	level: String
) -> void:
	var formatted := DLoggerFunc.format_log(msg, category, level, context, prefix, p_caller_info)
	var bbcode: String

	match level:
		"DEBUG":
			bbcode = "[color=gray]%s[/color]" % formatted
		"INFO":
			bbcode = "[b][color=cyan]%s[/color][/b]" % formatted
		"WARN":
			bbcode = "[b][color=yellow]%s[/color][/b]" % formatted
			push_warning(formatted)
		"ERROR":
			bbcode = "[b][color=red]%s[/color][/b]" % formatted
			push_error(formatted)
		_:
			bbcode = formatted

	print_rich(bbcode)
