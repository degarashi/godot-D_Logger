@tool
class_name DLoggerClass
extends RefCounted

# ------------- [Constants] -------------
const _DLOGGER_FILE = preload("uid://b3v27qs0f6a5e")
const _DLOGGER_FULL = preload("uid://bqce6prqiumic")
const _DLOGGER_QUIET = preload("uid://c253k62cylfjd")
const _LOG_ARRAY = preload("uid://c62dc0e0882d8")

# ------------- [Private Variable] -------------
static var _editor_panel: Object = null
static var _export_warning_shown: bool = false
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
		else ProjectSettings.get_setting(DLoggerConstants.SETTING_ENABLE_CONSOLE, false)
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

	# --- Export-build log-sink detection ---
	# In an exported runtime, EditorSettings (d_logger/...) are not available
	# and the in-memory mirror from DLoggerSettingsManager never persists
	# to project.godot (see AGENTS.md anti-pattern: never call
	# ProjectSettings.save() in plugin code). If the user only set the
	# file/console toggles in the editor and never wrote the corresponding
	# `debug/d_logger/...` keys to project.godot, this exported build
	# silently ends up with DLoggerQuiet only. Surface this once per
	# session in debug exports so the user has a chance to notice.
	if not _export_warning_shown and not Engine.is_editor_hint() and is_debug:
		if not console_enabled and not file_enabled:
			push_warning(
				(
					"DLogger: No log output configured for this exported debug build. "
					+ "Editor settings are not auto-persisted to project.godot. "
					+ "Add `debug/d_logger/enable_console_log = true` and/or "
					+ "`debug/d_logger/enable_file_log = true` to project.godot to enable."
				)
			)
		_export_warning_shown = true


func _dispatch(
	level: int,
	msg: String,
	values: Variant,
	category: String,
	context: Object,
	p_prefix: String,
	p_caller_info: Variant = null
) -> void:
	# Clear any stale cache from a previous failed _dispatch call
	DLoggerFunc.clear_time_cache()

	var pref := p_prefix if not p_prefix.is_empty() else _prefix
	var final_msg := msg
	var formatted := false

	match typeof(values):
		TYPE_DICTIONARY:
			if not (values as Dictionary).is_empty():
				final_msg = msg.format(values)
				formatted = true
		TYPE_ARRAY:
			if not (values as Array).is_empty():
				final_msg = msg.format(values)
				formatted = true
		_:
			# If not null and a primitive value is passed
			if values != null:
				final_msg = msg.format([values])
				formatted = true

	# Warn when placeholders survived formatting: the caller passed a
	# value type that does not match the placeholder style (e.g. a
	# Dictionary for positional {0}, or an Array for named {name}).
	# String.format() silently leaves such placeholders untouched, which
	# would otherwise log a broken message with no visible error.
	if formatted and DLoggerFunc.has_unresolved_placeholder(final_msg):
		push_warning(
			"DLogger: Unresolved format placeholder in message: %s"
			% final_msg
		)

	var level_str: String = DLoggerConstants.LOG_LEVEL_LABELS.get(level, "DEBUG")

	# Pre-calculate caller info for performance (one time per log)
	var caller_info: Variant = (
		p_caller_info if p_caller_info != null else DLoggerFunc.get_caller_info(level_str)
	)

	# Pre-compute time/frame once for all downstream loggers and debug_data
	var seconds: float = Time.get_ticks_msec() / 1000.0
	var frames: int = Engine.get_frames_drawn()
	DLoggerFunc.set_time_cache(seconds, frames)

	match level:
		DLoggerConstants.LogLevel.DEBUG:
			_dispatcher.debug(final_msg, [], category, context, pref, caller_info)
		DLoggerConstants.LogLevel.INFO:
			_dispatcher.info(final_msg, [], category, context, pref, caller_info)
		DLoggerConstants.LogLevel.WARN:
			_dispatcher.warn(final_msg, [], category, context, pref, caller_info)
		DLoggerConstants.LogLevel.ERROR:
			_dispatcher.error(final_msg, [], category, context, pref, caller_info)

			# Pause the tree if enabled
			if (
				OS.is_debug_build()
				and ProjectSettings.get_setting(DLoggerConstants.SETTING_PAUSE_ON_ERROR, false)
			):
				var tree := Engine.get_main_loop() as SceneTree
				if tree:
					tree.paused = true

	DLoggerFunc.clear_time_cache()

	# --- Process of sending to the editor debugger ---
	# Debug builds always reach the panel (direct call or via debugger).
	# Release builds also send when a debugger is attached (e.g., remote
	# debugging an exported game) — console/file output stays disabled there.
	# When nothing is listening the dictionary is not built at all.
	if EngineDebugger.is_active() or _editor_panel:
		# Pack the message to be sent to the editor side into a dictionary
		var debug_data: Dictionary = {
			"message": final_msg,
			"category": category,
			"level": level_str,
			"context_str": DLoggerFunc.get_object_string(context) if context else "",
			"caller_info": caller_info,
			"prefix": pref,
			"time": seconds,
			"frame": frames
		}

		if EngineDebugger.is_active():
			# Send data through a unique communication channel named 'd_logger:log'
			EngineDebugger.send_message("d_logger:log", [debug_data])
		elif _editor_panel and _editor_panel.has_method("add_log"):
			# Direct call to the panel when running inside the editor
			_editor_panel.add_log(debug_data)


# ------------- [Public Method] -------------
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
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null
) -> bool:
	if is_debug_enabled():
		_dispatch(DLoggerConstants.LogLevel.DEBUG, msg, v, cat, ctx, p, p_caller_info)
	return true


func info(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null
) -> bool:
	if is_info_enabled():
		_dispatch(DLoggerConstants.LogLevel.INFO, msg, v, cat, ctx, p, p_caller_info)
	return true


func warn(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null
) -> bool:
	if is_warn_enabled():
		_dispatch(DLoggerConstants.LogLevel.WARN, msg, v, cat, ctx, p, p_caller_info)
	return true


func error(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null
) -> bool:
	if is_error_enabled():
		_dispatch(DLoggerConstants.LogLevel.ERROR, msg, v, cat, ctx, p, p_caller_info)
	return true


# ------------- [Benchmark] -------------
## Measures the execution time of a callable and logs the result.
## Normal results are logged at INFO (category "PERF"); when the elapsed time
## exceeds `spike_threshold_ms` (default 16ms, one frame budget) the result
## is logged at WARN instead. Returns the callable's return value unchanged.
func benchmark(
	name: String,
	callable: Callable,
	spike_threshold_ms: float = 16.0
) -> Variant:
	if not callable.is_valid():
		# Bound callables can outlive their object; bail out with an error
		# instead of crashing on call().
		push_error("DLogger: benchmark '{0}' received an invalid callable".format([name]))
		return null

	var start_usec := Time.get_ticks_usec()
	var result: Variant = callable.call()
	var elapsed_ms := (Time.get_ticks_usec() - start_usec) / 1000.0

	if elapsed_ms >= spike_threshold_ms:
		warn(
			"PERF {0}: {1:.2f} ms (spike >= {2:.1f} ms)".format(
				[name, elapsed_ms, spike_threshold_ms]
			),
			[],
			"PERF"
		)
	else:
		info("PERF {0}: {1:.2f} ms".format([name, elapsed_ms]), [], "PERF")

	return result
