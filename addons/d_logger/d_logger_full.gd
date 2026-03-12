@tool
class_name DLoggerFull
extends DLoggerBase


func _format_log(_msg: Variant, category: String, level: String) -> String:
	var cat_str := ""
	if category != "":
		cat_str = "[%s] " % category

	return "%s %s%s [%s]" % [prefix, cat_str, _get_caller_info(), level]


func _get_caller_info() -> String:
	var stack := get_stack()
	if stack.size() >= 4:  # DLogger経由なので階層が1つ深くなる
		var caller: Dictionary = stack[3]
		return "[%s:%d]" % [caller.source.get_file(), caller.line]
	return ""


func debug(msg: Variant, category: String = "") -> void:
	print_rich("[color=gray]%s[/color] %s" % [_format_log(msg, category, "DEBUG"), str(msg)])


func info(msg: Variant, category: String = "") -> void:
	print_rich("[b][color=cyan]%s[/color][/b] %s" % [_format_log(msg, category, "INFO"), str(msg)])


func warn(msg: Variant, category: String = "") -> void:
	var header := _format_log(msg, category, "WARN")
	print_rich("[b][color=yellow]%s[/color][/b] %s" % [header, str(msg)])
	push_warning("%s %s" % [header, str(msg)])


func error(msg: Variant, category: String = "") -> void:
	var header := _format_log(msg, category, "ERROR")
	print_rich("[b][color=red]%s[/color][/b] %s" % [header, str(msg)])
	push_error("%s %s" % [header, str(msg)])
