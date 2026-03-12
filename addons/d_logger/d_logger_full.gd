@tool
class_name DLoggerFull
extends DLoggerBase


func _get_caller_info() -> String:
	var stack := get_stack()
	if stack.size() >= 3:
		var caller: Dictionary = stack[2]  # Get caller information
		# Format file name (without path) and line number
		var file_name: String = caller.source.get_file()
		return "[%s:%d]" % [file_name, caller.line]
	return ""


func debug(msg: Variant) -> void:
	print_rich("[color=gray]%s %s [DEBUG][/color] %s" % [prefix, _get_caller_info(), str(msg)])


func info(msg: Variant) -> void:
	print_rich(
		"[b][color=cyan]%s %s [INFO][/color][/b] %s" % [prefix, _get_caller_info(), str(msg)]
	)


func warn(msg: Variant) -> void:
	var info_str := _get_caller_info()
	var output := "%s %s [WARN] %s" % [prefix, info_str, str(msg)]
	print_rich("[b][color=yellow]%s[/color][/b]" % output)
	push_warning(output)


func error(msg: Variant) -> void:
	var info_str := _get_caller_info()
	var output := "%s %s [ERROR] %s" % [prefix, info_str, str(msg)]
	print_rich("[b][color=red]%s[/color][/b]" % output)
	push_error(output)
