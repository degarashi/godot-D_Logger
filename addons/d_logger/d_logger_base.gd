@tool
extends Object

const _C = preload("uid://cwfe01280qmo7")

var prefix: String = "D-Logger"
# Do not output logs less than this number
var min_level: int = _C.LogLevel.DEBUG


func debug(_msg: Variant, _category: String = "", _context: Object = null) -> void:
	pass


func info(_msg: Variant, _category: String = "", _context: Object = null) -> void:
	pass


func warn(_msg: Variant, _category: String = "", _context: Object = null) -> void:
	pass


func error(_msg: Variant, _category: String = "", _context: Object = null) -> void:
	pass
