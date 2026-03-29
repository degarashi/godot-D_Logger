class_name DLoggerClass
extends RefCounted

# ------------- [Constants] -------------
const _C = preload("uid://cwfe01280qmo7")
const _DLOGGER_FILE = preload("uid://b3v27qs0f6a5e")
const _DLOGGER_FULL = preload("uid://bqce6prqiumic")
const _DLOGGER_QUIET = preload("uid://c253k62cylfjd")
const _LOG_ARRAY = preload("uid://c62dc0e0882d8")

# ------------- [Private Variables] -------------
var _dispatcher := _LOG_ARRAY.new()
var _initialized := false

# Override variables
var _override_file_path: String = ""
var _override_console_enabled: bool = true
var _override_prefix: String = ""
var _override_min_level: int = _C.LogLevel.NOT_SPECIFIED

var _has_console_override := false
var _has_prefix_override := false

var _prefix: String = ""
var _min_level: int = 0


# ------------- [Constructor] -------------
func _init(
	p_prefix: Variant = null,
	p_min_lvl: int = _C.LogLevel.NOT_SPECIFIED,
	p_console_enabled: Variant = null,
	p_file_path: String = ""
) -> void:
	assert(DLoggerFunc.is_logger(self))
	if p_prefix is String:
		_override_prefix = p_prefix
		_has_prefix_override = true

	_override_min_level = p_min_lvl

	if p_console_enabled is bool:
		_override_console_enabled = p_console_enabled
		_has_console_override = true

	_override_file_path = p_file_path

	setup_logger()


# ------------- [Internal Methods] -------------
## Sets up the logger configuration
func setup_logger() -> void:
	# Reset dispatcher state
	_dispatcher.clear()

	var console_enabled: bool = (
		_override_console_enabled
		if _has_console_override
		else ProjectSettings.get_setting(_C.SETTING_ENABLE, true)
	)

	var file_enabled: bool = ProjectSettings.get_setting(_C.SETTING_ENABLE_FILE, false)
	var is_debug := OS.is_debug_build()

	# Add Console Logger
	if is_debug and console_enabled:
		_dispatcher.add(_DLOGGER_FULL.new())

	# Add File Logger
	if is_debug and file_enabled:
		var file_path: String = (
			_override_file_path
			if not _override_file_path.is_empty()
			else ProjectSettings.get_setting(_C.SETTING_FILE_PATH, _C.DEFAULT_FILE_PATH)
		)
		_dispatcher.add(_DLOGGER_FILE.new(file_path))

	# Fallback if none are enabled
	if _dispatcher.is_empty():
		_dispatcher.add(_DLOGGER_QUIET.new())

	_prefix = get_prefix()
	_min_level = get_min_level()
	_initialized = true


func _dispatch(
	level: int, msg: String, values: Variant, category: String, context: Object, p_prefix: String
) -> void:
	var pref := p_prefix if not p_prefix.is_empty() else _prefix
	var final_msg := msg

	if values is Dictionary or values is Array:
		final_msg = msg.format(values)
	elif values != null:
		final_msg = msg.format([values])

	match level:
		_C.LogLevel.DEBUG:
			_dispatcher.debug(final_msg, [], category, context, pref)
		_C.LogLevel.INFO:
			_dispatcher.info(final_msg, [], category, context, pref)
		_C.LogLevel.WARN:
			_dispatcher.warn(final_msg, [], category, context, pref)
		_C.LogLevel.ERROR:
			_dispatcher.error(final_msg, [], category, context, pref)


# ------------- [Public Methods] -------------
func get_prefix() -> String:
	if _has_prefix_override:
		return _override_prefix
	return ProjectSettings.get_setting(_C.SETTING_PREFIX, _C.DEFAULT_PREFIX)


func get_min_level() -> int:
	if _override_min_level != _C.LogLevel.NOT_SPECIFIED:
		return _override_min_level
	return ProjectSettings.get_setting(_C.SETTING_MIN_LEVEL, 0)


func is_debug_enabled() -> bool:
	return _min_level <= _C.LogLevel.DEBUG


func is_info_enabled() -> bool:
	return _min_level <= _C.LogLevel.INFO


func is_warn_enabled() -> bool:
	return _min_level <= _C.LogLevel.WARN


func is_error_enabled() -> bool:
	return _min_level <= _C.LogLevel.ERROR


# Use assert(log.debug(...)) if you want to disable output in release builds.


func debug(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	if is_debug_enabled():
		_dispatch(_C.LogLevel.DEBUG, msg, v, cat, ctx, p)
	return true


func info(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	if is_info_enabled():
		_dispatch(_C.LogLevel.INFO, msg, v, cat, ctx, p)
	return true


func warn(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	if is_warn_enabled():
		_dispatch(_C.LogLevel.WARN, msg, v, cat, ctx, p)
	return true


func error(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	if is_error_enabled():
		_dispatch(_C.LogLevel.ERROR, msg, v, cat, ctx, p)
	return true
