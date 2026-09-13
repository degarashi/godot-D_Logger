@tool
extends DLoggerBase


# ------------- [Level Checks] -------------
func is_debug_enabled() -> bool:
	return false


func is_info_enabled() -> bool:
	return false


# ------------- [Output] -------------
func _output(
	msg: String,
	values: Variant,
	category: String,
	context: Object,
	prefix: String,
	p_caller_info: Variant,
	level: String,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> void:
	var formatted := DLoggerFunc.format_log(
		msg,
		category,
		level,
		context,
		prefix,
		p_caller_info,
		p_seconds,
		p_frames
	)
	match level:
		"WARN":
			push_warning(formatted)
		"ERROR":
			push_error(formatted)
