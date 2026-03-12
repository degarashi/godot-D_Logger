@tool
class_name DLoggerQuiet
extends DLoggerBase

# debug and info do nothing


func warn(msg: Variant) -> void:
	push_warning("%s [WARN] %s" % [prefix, str(msg)])


func error(msg: Variant) -> void:
	push_error("%s [ERROR] %s" % [prefix, str(msg)])
