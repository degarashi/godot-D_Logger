@tool
class_name DLoggerFull
extends DLoggerBase


func _format_log(msg: Variant, category: String, level: String, context: Object) -> String:
	# Convert to seconds (e.g., 1234ms -> 1.234s)
	var seconds := Time.get_ticks_msec() / 1000.0
	var cat_str := category

	# Build context information
	var ctx_str := ""
	if context:
		# Display object name and hash (ID)
		ctx_str = "[%s:%d]" % [context.get_class(), context.get_instance_id()]

	# 7 characters total, 3 decimal places
	return (
		"[%7.3fs][%s]%s%s %s - [%s] %s"
		% [
			seconds,
			prefix,
			_get_caller_info(),
			ctx_str,
			cat_str,
			level,
			msg,
		]
	)


func _get_caller_info() -> String:
	var stack := get_stack()
	if stack.size() >= 5:  # Stack depth is one deeper due to DLogger
		var caller: Dictionary = stack[4]
		var caller_path: String = caller.source
		return "[%s:%d]" % [caller_path.get_file(), caller.line]
	return ""


func debug(msg: Variant, category: String = "", context: Object = null) -> void:
	print_rich("[color=gray]%s[/color]" % [_format_log(msg, category, "DEBUG", context)])


func info(msg: Variant, category: String = "", context: Object = null) -> void:
	print_rich("[b][color=cyan]%s[/color][/b]" % [_format_log(msg, category, "INFO", context)])


func warn(msg: Variant, category: String = "", context: Object = null) -> void:
	var header := _format_log(msg, category, "WARN", context)
	print_rich("[b][color=yellow]%s[/color][/b]" % [header])
	push_warning(header)


func error(msg: Variant, category: String = "", context: Object = null) -> void:
	var header := _format_log(msg, category, "ERROR", context)
	print_rich("[b][color=red]%s[/color][/b]" % [header])
	push_error(header)
