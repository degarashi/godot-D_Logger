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

	# WARN/ERROR are surfaced via push_warning/push_error only. Both already
	# write to the editor's Output panel (with stack trace + Errors tab entry),
	# so we deliberately skip print_rich for these levels to avoid double output.
	match level:
		"DEBUG":
			print_rich("[color=gray]%s[/color]" % safe_line)
		"INFO":
			print_rich("[b][color=cyan]%s[/color][/b]" % safe_line)
		"WARN":
			push_warning(formatted)
		"ERROR":
			push_error(formatted)
		_:
			print_rich(safe_line)
