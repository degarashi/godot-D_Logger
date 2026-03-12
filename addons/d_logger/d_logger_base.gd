@tool
class_name DLoggerBase
extends Object

enum LogLevel { DEBUG = 0, INFO = 1, WARN = 2, ERROR = 3 }

var prefix: String = "D-Logger"
# Do not output logs less than this number
var min_level: int = LogLevel.DEBUG


func debug(_msg: Variant, _category: String = "") -> void:
	pass


func info(_msg: Variant, _category: String = "") -> void:
	pass


func warn(_msg: Variant, _category: String = "") -> void:
	pass


func error(_msg: Variant, _category: String = "") -> void:
	pass
