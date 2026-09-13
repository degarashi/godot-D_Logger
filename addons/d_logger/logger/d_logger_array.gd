@tool
class_name DLoggerArray
extends DLoggerBase

# Dispatcher holding child loggers. Inherits the template pattern from
# DLoggerBase (level checks + debug/info/warn/error) and only overrides
# the _output() hook to fan out, so the forwarding rule lives in one place.
# _list stays Array[RefCounted] on purpose: child loggers only need the
# duck-typed logger interface (see DLoggerFunc.is_logger), not necessarily
# a DLoggerBase descendant.

# ------------- [Public Variable] -------------
var _list: Array[RefCounted] = []


# ------------- [Public Method] -------------
func clear() -> void:
	_list.clear()


func add(logger: RefCounted) -> void:
	assert(logger != null, "logger must not be null")
	# Fail fast here instead of inside the dispatch loop: a non-logger
	# would otherwise crash mid-dispatch after earlier loggers already
	# wrote, leaving partial output for a single log call.
	assert(
		DLoggerFunc.is_logger(logger),
		"logger must implement the logger interface"
	)
	_list.append(logger)


func is_empty() -> bool:
	return _list.is_empty()


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
	# Fan out to children via their own level-gated entry points, so each
	# child (e.g. DLoggerQuiet suppressing DEBUG/INFO) applies its filter.
	# The dispatcher-computed timestamp travels with the call so all
	# children share one reading instead of sampling the clock per sink.
	match level:
		"DEBUG":
			for l in _list:
				l.debug(
					msg,
					values,
					category,
					context,
					prefix,
					p_caller_info,
					p_seconds,
					p_frames
				)
		"INFO":
			for l in _list:
				l.info(
					msg,
					values,
					category,
					context,
					prefix,
					p_caller_info,
					p_seconds,
					p_frames
				)
		"WARN":
			for l in _list:
				l.warn(
					msg,
					values,
					category,
					context,
					prefix,
					p_caller_info,
					p_seconds,
					p_frames
				)
		"ERROR":
			for l in _list:
				l.error(
					msg,
					values,
					category,
					context,
					prefix,
					p_caller_info,
					p_seconds,
					p_frames
				)
