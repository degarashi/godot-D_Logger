@tool
class_name DLoggerQuiet
extends DLoggerBase

# debug and info do nothing


func warn(msg: Variant, category: String = "") -> void:
	var cat_str := ""
	if category != "":
		cat_str = "[%s] " % category

	push_warning("%s %s[WARN] %s" % [prefix, cat_str, str(msg)])


func error(msg: Variant, category: String = "") -> void:
	var cat_str := ""
	if category != "":
		cat_str = "[%s] " % category

	push_error("%s %s[ERROR] %s" % [prefix, cat_str, str(msg)])
