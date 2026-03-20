@tool

const _C = preload("uid://cwfe01280qmo7")


# debug and info do nothing
func debug(
	_msg: String, _category: String = "", _context: Object = null, _prefix: String = ""
) -> void:
	pass


func info(
	_msg: String, _category: String = "", _context: Object = null, _prefix: String = ""
) -> void:
	pass


func warn(msg: String, category: String = "", context: Object = null, prefix: String = "") -> void:
	var header := _C.format_log(msg, category, "WARN", context, prefix)
	push_warning(header)


func error(msg: String, category: String = "", context: Object = null, prefix: String = "") -> void:
	var header := _C.format_log(msg, category, "ERROR", context, prefix)
	push_error(header)
