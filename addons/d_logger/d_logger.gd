class_name DLoggerClass
extends RefCounted

# ------------- [Constants] -------------
const _DLOGGER_FILE = preload("uid://b3v27qs0f6a5e")
const _DLOGGER_FULL = preload("uid://bqce6prqiumic")
const _DLOGGER_QUIET = preload("uid://c253k62cylfjd")
const _LOG_ARRAY = preload("uid://c62dc0e0882d8")

# ------------- [Private Variables] -------------
var _dispatcher := _LOG_ARRAY.new()
var _initialized := false

# Override variables
var _override_file_path: String = ""
var _override_console_enabled: bool = false
var _override_prefix: String = ""
var _override_min_level: int = DLoggerConstants.LogLevel.NOT_SPECIFIED

var _has_console_override := false
var _has_prefix_override := false

var _prefix: String = ""
var _min_level: int = 0


# ------------- [Constructor] -------------
func _init(
	p_prefix: Variant = null,
	p_min_lvl: int = DLoggerConstants.LogLevel.NOT_SPECIFIED,
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
		else ProjectSettings.get_setting(DLoggerConstants.SETTING_ENABLE, false)
	)

	var file_enabled: bool = ProjectSettings.get_setting(
		DLoggerConstants.SETTING_ENABLE_FILE, false
	)
	var is_debug := OS.is_debug_build()

	# Add Console Logger
	if is_debug and console_enabled:
		_dispatcher.add(_DLOGGER_FULL.new())

	# Add File Logger
	if is_debug and file_enabled:
		var file_path: String = (
			_override_file_path
			if not _override_file_path.is_empty()
			else ProjectSettings.get_setting(
				DLoggerConstants.SETTING_FILE_PATH, DLoggerConstants.DEFAULT_FILE_PATH
			)
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

	match typeof(values):
		TYPE_DICTIONARY:
			if not (values as Dictionary).is_empty():
				final_msg = msg.format(values)
		TYPE_ARRAY:
			if not (values as Array).is_empty():
				final_msg = msg.format(values)
		_:
			# If not null and a primitive value is passed
			if values != null:
				final_msg = msg.format([values])

	match level:
		DLoggerConstants.LogLevel.DEBUG:
			_dispatcher.debug(final_msg, [], category, context, pref)
		DLoggerConstants.LogLevel.INFO:
			_dispatcher.info(final_msg, [], category, context, pref)
		DLoggerConstants.LogLevel.WARN:
			_dispatcher.warn(final_msg, [], category, context, pref)
		DLoggerConstants.LogLevel.ERROR:
			_dispatcher.error(final_msg, [], category, context, pref)

	# --- Process of sending to the editor debugger ---
	if OS.is_debug_build() and EngineDebugger.is_active():
		var level_str := "DEBUG"
		match level:
			DLoggerConstants.LogLevel.INFO:
				level_str = "INFO"
			DLoggerConstants.LogLevel.WARN:
				level_str = "WARN"
			DLoggerConstants.LogLevel.ERROR:
				level_str = "ERROR"

		# Pack the message to be sent to the editor side into a dictionary
		var debug_data: Dictionary = {
			"message": final_msg,
			"category": category,
			"level": level_str,
			"context_str": DLoggerFunc.get_object_string(context) if context else "",
			"prefix": pref,
			"time": Time.get_ticks_msec() / 1000.0,
			"frame": Engine.get_frames_drawn()
		}

		# Send data through a unique communication channel named 'd_logger:log'
		EngineDebugger.send_message("d_logger:log", [debug_data])


# ------------- [Public Methods] -------------
func get_prefix() -> String:
	if _has_prefix_override:
		return _override_prefix
	return ProjectSettings.get_setting(
		DLoggerConstants.SETTING_PREFIX, DLoggerConstants.DEFAULT_PREFIX
	)


func get_min_level() -> int:
	if _override_min_level != DLoggerConstants.LogLevel.NOT_SPECIFIED:
		return _override_min_level
	return ProjectSettings.get_setting(DLoggerConstants.SETTING_MIN_LEVEL, 0)


func is_debug_enabled() -> bool:
	return _min_level <= DLoggerConstants.LogLevel.DEBUG


func is_info_enabled() -> bool:
	return _min_level <= DLoggerConstants.LogLevel.INFO


func is_warn_enabled() -> bool:
	return _min_level <= DLoggerConstants.LogLevel.WARN


func is_error_enabled() -> bool:
	return _min_level <= DLoggerConstants.LogLevel.ERROR


# Use assert(log.debug(...)) if you want to disable output in release builds.


func debug(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	if is_debug_enabled():
		_dispatch(DLoggerConstants.LogLevel.DEBUG, msg, v, cat, ctx, p)
	return true


func info(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	if is_info_enabled():
		_dispatch(DLoggerConstants.LogLevel.INFO, msg, v, cat, ctx, p)
	return true


func warn(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	if is_warn_enabled():
		_dispatch(DLoggerConstants.LogLevel.WARN, msg, v, cat, ctx, p)
	return true


func error(
	msg: String, v: Variant = [], cat: String = "", ctx: Object = null, p: String = ""
) -> bool:
	if is_error_enabled():
		_dispatch(DLoggerConstants.LogLevel.ERROR, msg, v, cat, ctx, p)
	return true
