@tool
extends RefCounted


func debug(
	_msg: String, _category: String = "", _context: Object = null, _prefix: String = ""
) -> void:
	pass


func info(
	_msg: String, _category: String = "", _context: Object = null, _prefix: String = ""
) -> void:
	pass


func warn(
	_msg: Variant, _category: String = "", _context: Object = null, _prefix: String = ""
) -> void:
	pass


func error(
	_msg: Variant, _category: String = "", _context: Object = null, _prefix: String = ""
) -> void:
	pass
