@tool
class_name DLoggerBase
extends Object

var prefix: String = "D-Logger"


func debug(_msg: Variant, _category: String = "") -> void:
	pass


func info(_msg: Variant, _category: String = "") -> void:
	pass


func warn(_msg: Variant, _category: String = "") -> void:
	pass


func error(_msg: Variant, _category: String = "") -> void:
	pass
