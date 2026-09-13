@tool
class_name DLoggerClass
extends RefCounted

# ------------- [Constants] -------------
const _DLOGGER_FILE = preload("uid://b3v27qs0f6a5e")
const _DLOGGER_FULL = preload("uid://bqce6prqiumic")
const _DLOGGER_QUIET = preload("uid://c253k62cylfjd")
const _LOG_ARRAY = preload("uid://c62dc0e0882d8")
## Default spike threshold for benchmark(): one frame budget at 60fps.
const DEFAULT_SPIKE_THRESHOLD_MS := 16.0

# ------------- [Private Variable] -------------
static var _editor_panel: Object = null
static var _export_warning_shown: bool = false
# Message templates whose unresolved-placeholder warning has already been
# shown. Deduplicates the warning per call-site template so literal brace
# text logged in a hot loop (regex quantifiers like \d{2}, config samples)
# does not flood the Output dock. A Dictionary used as a set for O(1)
# lookup. Bounded by _warn_limit.
static var _placeholder_warned: Dictionary = {}
static var _warn_limit := 128
## Variant to avoid a cyclic self-reference during class loading.
static var _static_fallback: Variant = null
# Watches the runtime d_logger settings for the static fallback.
# get_static_logger() rebuilds the fallback via setup_logger() only
# when poll() reports drift (same guard as DLoggerNode, which
# additionally avoids spurious file session markers).
static var _settings_watcher: DLoggerSettingsWatcher = null
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
var _min_level: int = DLoggerConstants.LogLevel.DEBUG
# Reusable outputs across setup_logger() rebuilds. Rebuilding used to
# construct a new file logger every time, appending a duplicate
# "=== New Session Started ===" marker per rebuild (bulk settings
# syncs still emit more than once). Reuse keeps one instance per
# path epoch; a changed path still constructs a fresh logger.
var _cached_console: RefCounted = null
var _cached_file: RefCounted = null
var _cached_file_path: String = ""


# ------------- [Constructor] -------------
func _init(
	p_prefix: Variant = null,
	p_min_lvl: int = DLoggerConstants.LogLevel.NOT_SPECIFIED,
	p_console_enabled: Variant = null,
	p_file_path: String = "",
	p_force_console: bool = false
) -> void:
	assert(DLoggerFunc.is_logger(self))
	_store_overrides(p_prefix, p_min_lvl, p_console_enabled, p_file_path)
	setup_logger(p_force_console)


## Stores constructor overrides without touching the dispatcher, so _init
## stays a thin orchestration of store + rebuild.
func _store_overrides(
	p_prefix: Variant,
	p_min_lvl: int,
	p_console_enabled: Variant,
	p_file_path: String
) -> void:
	if p_prefix is String:
		_override_prefix = p_prefix
		_has_prefix_override = true
	_override_min_level = p_min_lvl
	if p_console_enabled is bool:
		_override_console_enabled = p_console_enabled
		_has_console_override = true
	_override_file_path = p_file_path


# ------------- [Setup] -------------
## Sets up the logger configuration. When force_console is true,
## console output is added regardless of ProjectSettings/build type.
func setup_logger(force_console: bool = false) -> void:
	# Reset dispatcher state
	_dispatcher.clear()

	var console_enabled := _is_console_enabled()
	var file_enabled := _is_file_enabled()
	var is_debug := OS.is_debug_build()

	_build_console_logger(force_console, console_enabled, is_debug)
	_build_file_logger(file_enabled, is_debug)
	_ensure_fallback_logger()

	_prefix = get_prefix()
	_min_level = get_min_level()
	_initialized = true

	_maybe_warn_export_no_sink(console_enabled, file_enabled, is_debug)


## Resolves the effective console toggle: explicit override wins,
## otherwise the runtime ProjectSettings value is used.
func _is_console_enabled() -> bool:
	if _has_console_override:
		return _override_console_enabled
	return ProjectSettings.get_setting(
		DLoggerConstants.SETTING_ENABLE_CONSOLE, false
	)


## Resolves the effective file toggle from runtime ProjectSettings.
func _is_file_enabled() -> bool:
	return ProjectSettings.get_setting(
		DLoggerConstants.SETTING_ENABLE_FILE, false
	)


## Resolves the effective file path: explicit override wins,
## otherwise the runtime ProjectSettings value is used.
func _resolve_file_path() -> String:
	if not _override_file_path.is_empty():
		return _override_file_path
	return ProjectSettings.get_setting(
		DLoggerConstants.SETTING_FILE_PATH, DLoggerConstants.DEFAULT_FILE_PATH
	)


## Adds the console logger when forced or enabled in a debug build.
## The instance is reused across rebuilds: it is stateless, so reuse
## only skips a redundant allocation.
func _build_console_logger(
	force_console: bool, console_enabled: bool, is_debug: bool
) -> void:
	if not (force_console or (is_debug and console_enabled)):
		return
	if _cached_console == null:
		_cached_console = _DLOGGER_FULL.new()
	_dispatcher.add(_cached_console)


## Adds the file logger when enabled in a debug build. The instance is
## reused while the resolved path is unchanged so repeated rebuilds
## neither reopen the file nor duplicate the session-start marker;
## a new path still starts a fresh file.
func _build_file_logger(file_enabled: bool, is_debug: bool) -> void:
	if not (is_debug and file_enabled):
		return
	var file_path := _resolve_file_path()
	if _cached_file == null or _cached_file_path != file_path:
		_cached_file = _DLOGGER_FILE.new(file_path)
		_cached_file_path = file_path
	_dispatcher.add(_cached_file)


## Guarantees at least one sink so no log call crashes on an empty
## dispatcher; the quiet fallback only surfaces WARN/ERROR.
func _ensure_fallback_logger() -> void:
	if _dispatcher.is_empty():
		_dispatcher.add(_DLOGGER_QUIET.new())


## Warns once per session when an exported debug build has no sink.
## In an exported runtime, EditorSettings (d_logger/...) are not available
## and the in-memory mirror from DLoggerSettingsManager never persists
## to project.godot (see AGENTS.md anti-pattern: never call
## ProjectSettings.save() in plugin code). If the user only set the
## file/console toggles in the editor and never wrote the corresponding
## `debug/d_logger/...` keys to project.godot, this exported build
## silently ends up with DLoggerQuiet only. Headless `-s` script runs are
## excluded: they have no game loop or export packaging involved, and the
## static fallback already forces console output there.
func _maybe_warn_export_no_sink(
	console_enabled: bool, file_enabled: bool, is_debug: bool
) -> void:
	if _export_warning_shown:
		return
	if Engine.is_editor_hint():
		return
	if not is_debug:
		return
	if DisplayServer.get_name() == "headless":
		return
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


# ------------- [Dispatch] -------------
func _dispatch(
	level: int,
	msg: String,
	values: Variant,
	category: String,
	context: Object,
	p_prefix: String,
	p_caller_info: Variant = null,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> void:
	var pref := p_prefix if not p_prefix.is_empty() else _prefix
	var applied := _apply_values(msg, values)
	var final_msg: String = applied[0]
	var formatted: bool = applied[1]
	_maybe_warn_unresolved_placeholder(msg, final_msg, formatted)

	var level_str: String = DLoggerConstants.LOG_LEVEL_LABELS.get(
		level, "DEBUG"
	)

	# Pre-calculate caller info for performance (one time per log)
	var caller_info: Variant = _resolve_caller_info(level_str, p_caller_info)

	# Sample time/frame once per log and thread it through the dispatcher
	# and the editor payload, so all sinks share one reading without
	# sampling the clock per sink or sharing state across dispatches.
	# A forwarded reading (>= 0) is reused; otherwise sample here.
	var seconds: float = (
		p_seconds if p_seconds >= 0.0 else Time.get_ticks_msec() / 1000.0
	)
	var frames: int = p_frames if p_frames >= 0 else Engine.get_frames_drawn()

	_forward_to_dispatcher(
		level, final_msg, category, context, pref, caller_info, seconds, frames
	)
	_maybe_pause_on_error(level)

	_send_to_editor(
		level_str,
		final_msg,
		category,
		context,
		caller_info,
		pref,
		seconds,
		frames
	)


## Applies String.format() to the template. Returns [message, formatted]
## where formatted reports whether values were actually passed, so the
## caller can distinguish literal braces (no values) from a type mismatch
## (values passed but placeholders survived). An Array return avoids a
## Dictionary allocation on every log call in hot paths.
static func _apply_values(msg: String, values: Variant) -> Array:
	match typeof(values):
		TYPE_DICTIONARY:
			if not (values as Dictionary).is_empty():
				return [msg.format(values), true]
		TYPE_ARRAY:
			if not (values as Array).is_empty():
				return [msg.format(values), true]
		_:
			# If not null and a primitive value is passed
			if values != null:
				return [msg.format([values]), true]
	return [msg, false]


## Warns only when the caller actually passed values (formatted) yet
## placeholders survived: the value type does not match the
## placeholder style (e.g. a Dictionary for positional {0}, or an
## Array for named {name}). Messages logged without values are
## skipped on purpose: literal braces in user text (JSON snippets,
## regex quantifiers like \d{2}) are indistinguishable from
## placeholders, and warning on them would flag every such log once.
## Trade-off: forgetting to pass values for a real placeholder no
## longer warns — accepted because String.format() offers no escape
## syntax to tell the two cases apart.
static func _maybe_warn_unresolved_placeholder(
	template: String, final_msg: String, formatted: bool
) -> void:
	if not formatted:
		return
	if not DLoggerFunc.has_unresolved_placeholder(final_msg):
		return
	# Keyed on the pre-format template: identical call sites share a
	# single warning regardless of the substituted values.
	if _placeholder_warned.has(template):
		return
	if _placeholder_warned.size() >= _warn_limit:
		# Simple wholesale reset instead of an LRU: after it,
		# old templates may warn once more, which is acceptable
		# for a heuristic warning.
		_placeholder_warned.clear()
	_placeholder_warned[template] = true
	push_warning(
		"DLogger: Unresolved format placeholder in message: %s" % final_msg
	)


## Returns the explicit caller info when provided, otherwise captures it
## once per log so downstream loggers share the same value.
static func _resolve_caller_info(
	level_str: String, p_caller_info: Variant
) -> Variant:
	if p_caller_info != null:
		return p_caller_info
	return DLoggerFunc.get_caller_info(level_str)


## Forwards the already-formatted message to the dispatcher. Values are
## always empty here because formatting happened in _apply_values(). The
## sampled timestamp travels along so every sink formats the same reading.
func _forward_to_dispatcher(
	level: int,
	final_msg: String,
	category: String,
	context: Object,
	pref: String,
	caller_info: Variant,
	seconds: float,
	frames: int
) -> void:
	match level:
		DLoggerConstants.LogLevel.DEBUG:
			_dispatcher.debug(
				final_msg,
				[],
				category,
				context,
				pref,
				caller_info,
				seconds,
				frames
			)
		DLoggerConstants.LogLevel.INFO:
			_dispatcher.info(
				final_msg,
				[],
				category,
				context,
				pref,
				caller_info,
				seconds,
				frames
			)
		DLoggerConstants.LogLevel.WARN:
			_dispatcher.warn(
				final_msg,
				[],
				category,
				context,
				pref,
				caller_info,
				seconds,
				frames
			)
		DLoggerConstants.LogLevel.ERROR:
			_dispatcher.error(
				final_msg,
				[],
				category,
				context,
				pref,
				caller_info,
				seconds,
				frames
			)


## Pauses the tree on ERROR when enabled. Skipped in editor because a
## @tool script that fires an error would otherwise pause the editor's
## own main loop (EditorSceneTree is a SceneTree), freezing the editor.
func _maybe_pause_on_error(level: int) -> void:
	if level != DLoggerConstants.LogLevel.ERROR:
		return
	if not OS.is_debug_build():
		return
	if Engine.is_editor_hint():
		return
	if not ProjectSettings.get_setting(
		DLoggerConstants.SETTING_PAUSE_ON_ERROR, false
	):
		return
	var tree := Engine.get_main_loop() as SceneTree
	if tree:
		tree.paused = true


## Sends the log to the editor panel. Debug builds always reach the panel
## (direct call or via debugger). Release builds also send when a debugger
## is attached (e.g., remote debugging an exported game) — console/file
## output stays disabled there. When nothing is listening the dictionary
## is not built at all.
func _send_to_editor(
	level_str: String,
	final_msg: String,
	category: String,
	context: Object,
	caller_info: Variant,
	pref: String,
	seconds: float,
	frames: int
) -> void:
	if not (EngineDebugger.is_active() or _editor_panel):
		return
	# Pack the message to be sent to the editor side into a dictionary
	var debug_data: Dictionary = {
		"message": final_msg,
		"category": category,
		"level": level_str,
		"context_str":
		DLoggerFunc.get_object_string(context) if context else "",
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
	return ProjectSettings.get_setting(
		DLoggerConstants.SETTING_MIN_LEVEL, DLoggerConstants.LogLevel.DEBUG
	)


## Single comparison behind is_* so the threshold rule lives in one place.
func _is_level_enabled(level: int) -> bool:
	return _min_level <= level


func is_debug_enabled() -> bool:
	return _is_level_enabled(DLoggerConstants.LogLevel.DEBUG)


func is_info_enabled() -> bool:
	return _is_level_enabled(DLoggerConstants.LogLevel.INFO)


func is_warn_enabled() -> bool:
	return _is_level_enabled(DLoggerConstants.LogLevel.WARN)


func is_error_enabled() -> bool:
	return _is_level_enabled(DLoggerConstants.LogLevel.ERROR)


# ------------- [Static Facade - headless-safe] -------------
## Sets the editor panel receiving direct log calls inside the editor.
## Managed by the EditorPlugin lifecycle; kept behind a setter so the
## static wiring point stays explicit and testable.
static func set_editor_panel(panel: Object) -> void:
	_editor_panel = panel


## Returns the Autoload logger when available, otherwise null.
## Callers wanting the fallback behavior should use
## get_static_logger() instead.
static func _find_autoload_logger() -> DLoggerClass:
	var loop: Object = Engine.get_main_loop()
	if loop is SceneTree:
		var root: Window = (loop as SceneTree).root
		if root != null:
			var node: Node = root.get_node_or_null(
				DLoggerConstants.AUTOLOAD_NAME
			)
			if node != null:
				var lg: Object = DLoggerFunc.get_logger(node)
				if lg is DLoggerClass:
					return lg as DLoggerClass
	return null


## Returns true when the static fallback must force console output
## regardless of settings: headless `-s` contexts have no Autoload
## and default settings leave console disabled, so without forcing
## they would print nothing. Static so the decision is testable
## without building a fallback instance.
static func _should_force_fallback_console() -> bool:
	return DisplayServer.get_name() == "headless"


## Returns the effective logger: Autoload instance when available,
## otherwise a process-wide fallback. Headless `-s` contexts have
## no Autoload, so the fallback avoids
## `Identifier not found: DLogger` and still prints (console is
## forced there only; elsewhere the fallback follows
## ProjectSettings like DLoggerNode).
static func get_static_logger() -> DLoggerClass:
	var autoload_logger: DLoggerClass = _find_autoload_logger()
	if autoload_logger != null:
		return autoload_logger
	var force_console := _should_force_fallback_console()
	if _static_fallback == null:
		# No prefix/level/console override (null/NOT_SPECIFIED):
		# non-headless runs follow ProjectSettings like DLoggerNode;
		# headless forces console via the flag only.
		_static_fallback = DLoggerClass.new(
			null,
			DLoggerConstants.LogLevel.NOT_SPECIFIED,
			null,
			"",
			force_console
		)
		_settings_watcher = DLoggerSettingsWatcher.new()
	elif _settings_watcher.poll():
		(_static_fallback as DLoggerClass).setup_logger(force_console)
	return _static_fallback as DLoggerClass


static func is_static_available() -> bool:
	return _find_autoload_logger() != null


## Dispatches to the matching level; unknown levels warn and
## fall back to INFO so no message is silently lost.
static func static_log(
	level: int,
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null
) -> bool:
	var lg: DLoggerClass = get_static_logger()
	match level:
		DLoggerConstants.LogLevel.DEBUG:
			return lg.debug(msg, v, cat, ctx, p, p_caller_info)
		DLoggerConstants.LogLevel.INFO:
			return lg.info(msg, v, cat, ctx, p, p_caller_info)
		DLoggerConstants.LogLevel.WARN:
			return lg.warn(msg, v, cat, ctx, p, p_caller_info)
		DLoggerConstants.LogLevel.ERROR:
			return lg.error(msg, v, cat, ctx, p, p_caller_info)
		_:
			push_warning(
				"DLogger: Unknown log level '{0}', falling back to INFO".format(
					[level]
				)
			)
			return lg.info(msg, v, cat, ctx, p, p_caller_info)


## Logs at DEBUG via the static logger. The caller is attributed
## to the call site outside the addon (addon frames are skipped).
static func static_debug(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null
) -> bool:
	return static_log(
		DLoggerConstants.LogLevel.DEBUG, msg, v, cat, ctx, p, p_caller_info
	)


## Logs at INFO via the static logger. The caller is attributed
## to the call site outside the addon (addon frames are skipped).
static func static_info(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null
) -> bool:
	return static_log(
		DLoggerConstants.LogLevel.INFO, msg, v, cat, ctx, p, p_caller_info
	)


## Logs at WARN via the static logger. The caller is attributed
## to the call site outside the addon (addon frames are skipped).
static func static_warn(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null
) -> bool:
	return static_log(
		DLoggerConstants.LogLevel.WARN, msg, v, cat, ctx, p, p_caller_info
	)


## Logs at ERROR via the static logger. The caller is attributed
## to the call site outside the addon (addon frames are skipped).
static func static_error(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null
) -> bool:
	return static_log(
		DLoggerConstants.LogLevel.ERROR, msg, v, cat, ctx, p, p_caller_info
	)


## Returns the effective prefix of the static logger.
static func static_get_prefix() -> String:
	return get_static_logger().get_prefix()


## Returns the effective minimum level of the static logger.
static func static_get_min_level() -> int:
	return get_static_logger().get_min_level()


## Returns true when DEBUG is enabled on the static logger.
static func static_is_debug_enabled() -> bool:
	return get_static_logger().is_debug_enabled()


## Returns true when INFO is enabled on the static logger.
static func static_is_info_enabled() -> bool:
	return get_static_logger().is_info_enabled()


## Returns true when WARN is enabled on the static logger.
static func static_is_warn_enabled() -> bool:
	return get_static_logger().is_warn_enabled()


## Returns true when ERROR is enabled on the static logger.
static func static_is_error_enabled() -> bool:
	return get_static_logger().is_error_enabled()


## Measures the execution time of a callable via the static logger.
## See benchmark() for details.
static func static_benchmark(
	name: String,
	callable: Callable,
	spike_threshold_ms: float = DEFAULT_SPIKE_THRESHOLD_MS
) -> Variant:
	return get_static_logger().benchmark(name, callable, spike_threshold_ms)


# Use assert(log.debug(...)) if you want to disable output in release builds.


## Shared gate behind debug/info/warn/error: filtered levels still return
## true so the calls double as assert() conditions without failing when
## the level is disabled. The trailing timestamp mirrors DLoggerBase so
## node wrappers can forward a sampled reading; callers normally omit it.
func _log(
	level: int,
	msg: String,
	v: Variant,
	cat: String,
	ctx: Object,
	p: String,
	p_caller_info: Variant,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> bool:
	if _is_level_enabled(level):
		_dispatch(
			level, msg, v, cat, ctx, p, p_caller_info, p_seconds, p_frames
		)
	return true


func debug(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> bool:
	return _log(
		DLoggerConstants.LogLevel.DEBUG,
		msg,
		v,
		cat,
		ctx,
		p,
		p_caller_info,
		p_seconds,
		p_frames
	)


func info(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> bool:
	return _log(
		DLoggerConstants.LogLevel.INFO,
		msg,
		v,
		cat,
		ctx,
		p,
		p_caller_info,
		p_seconds,
		p_frames
	)


func warn(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> bool:
	return _log(
		DLoggerConstants.LogLevel.WARN,
		msg,
		v,
		cat,
		ctx,
		p,
		p_caller_info,
		p_seconds,
		p_frames
	)


func error(
	msg: String,
	v: Variant = [],
	cat: String = "",
	ctx: Object = null,
	p: String = "",
	p_caller_info: Variant = null,
	p_seconds: float = -1.0,
	p_frames: int = -1
) -> bool:
	return _log(
		DLoggerConstants.LogLevel.ERROR,
		msg,
		v,
		cat,
		ctx,
		p,
		p_caller_info,
		p_seconds,
		p_frames
	)


# ------------- [Benchmark] -------------
## Measures the execution time of a callable and logs the result.
## The callable must take no arguments (it is invoked via
## `callable.call()`); bind arguments beforehand with `bind()`.
## Normal results are logged at INFO (category "PERF"), so they are
## hidden when the minimum level is WARN or higher; when the elapsed
## time exceeds `spike_threshold_ms` (default
## DEFAULT_SPIKE_THRESHOLD_MS, one frame budget) the result is logged
## at WARN instead and stays visible. Returns the callable's return
## value unchanged.
func benchmark(
	name: String,
	callable: Callable,
	spike_threshold_ms: float = DEFAULT_SPIKE_THRESHOLD_MS
) -> Variant:
	if not callable.is_valid():
		# Bound callables can outlive their object; bail out with an error
		# instead of crashing on call().
		push_error(
			"DLogger: benchmark '{0}' received an invalid callable".format(
				[name]
			)
		)
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
