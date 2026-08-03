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
	# Escape brackets before embedding into BBCode so user-provided message
	# text cannot inject markup. Renders identically: unknown tags and
	# escaped brackets both display as literal text.
	var safe_line := DLoggerFunc.escape_bbcode(formatted)
	var bbcode: String

	match level:
		"DEBUG":
			bbcode = "[color=gray]%s[/color]" % safe_line
		"INFO":
			bbcode = "[b][color=cyan]%s[/color][/b]" % safe_line
		"WARN":
			bbcode = "[b][color=yellow]%s[/color][/b]" % safe_line
			push_warning(formatted)
		"ERROR":
			bbcode = "[b][color=red]%s[/color][/b]" % safe_line
			push_error(formatted)
		_:
			bbcode = safe_line

	print_rich(bbcode)
