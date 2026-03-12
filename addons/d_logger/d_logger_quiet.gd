@tool
class_name DLoggerQuiet
extends DLoggerBase

# debug and info do nothing


func warn(msg: Variant, category: String = "") -> void:
	var seconds := Time.get_ticks_msec() / 1000.0
	var cat_str := ""
	if category != "":
		cat_str = "[%s] " % category

	push_warning("[%.3fs] %s %s[WARN] %s" % [seconds, prefix, cat_str, str(msg)])


func error(msg: Variant, category: String = "") -> void:
	var seconds := Time.get_ticks_msec() / 1000.0
	var cat_str := ""
	if category != "":
		cat_str = "[%s] " % category

	push_error("[%.3fs] %s %s[ERROR] %s" % [seconds, prefix, cat_str, str(msg)])
