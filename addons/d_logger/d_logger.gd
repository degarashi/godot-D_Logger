@tool
extends Node

const _C = preload("uid://cwfe01280qmo7")
const _DLOGGER_FILE = preload("uid://b3v27qs0f6a5e")
const _DLOGGER_FULL = preload("uid://bqce6prqiumic")
const _DLOGGER_QUIET = preload("uid://c253k62cylfjd")

# Array to hold multiple loggers
var _loggers: Array[RefCounted] = []

var _first_time := true

# Override values with specific types
var _override_file_path: String = ""
var _override_console_enabled: bool = true
var _override_prefix: String = ""
var _override_min_level: int = -1

# Flag to check if bool/string overrides are active
var _has_console_override: bool = false
var _has_prefix_override: bool = false

var _prefix: String
var _min_level: int


func _init(
	p_prefix: Variant = null,
	p_min_lvl: int = -1,
	p_console_enabled: Variant = null,
	p_file_path: String = ""
) -> void:
	if p_prefix is String:
		_override_prefix = p_prefix
		_has_prefix_override = true

	_override_min_level = p_min_lvl

	if p_console_enabled is bool:
		_override_console_enabled = p_console_enabled
		_has_console_override = true

	_override_file_path = p_file_path

	# Force re-setup if already initialized
	_first_time = true
	_setup_logger()


func _enter_tree() -> void:
	_setup_logger()
	if not ProjectSettings.settings_changed.is_connected(_setup_logger):
		ProjectSettings.settings_changed.connect(_setup_logger)


func get_prefix() -> String:
	if _has_prefix_override:
		return _override_prefix
	return ProjectSettings.get_setting(_C.SETTING_PREFIX, _C.DEFAULT_PREFIX)


func get_min_level() -> int:
	if _override_min_level != -1:
		return _override_min_level
	return ProjectSettings.get_setting(_C.SETTING_MIN_LEVEL, 0)


## Sets up the logger configuration (Factory & Multi-cast)
func _setup_logger() -> void:
	if not _first_time:
		return

	_first_time = false
	_loggers.clear()

	var console_enabled: bool = (
		_override_console_enabled
		if _has_console_override
		else ProjectSettings.get_setting(_C.SETTING_ENABLE, true)
	)

	var file_enabled: bool = ProjectSettings.get_setting(_C.SETTING_ENABLE_FILE, false)
	# Retrieve settings with potential overrides
	var is_debug := OS.is_debug_build()

	# Construct console logger
	if is_debug and console_enabled:
		_loggers.append(_DLOGGER_FULL.new())

	# Construct file output logger
	if is_debug and file_enabled:
		var file_path: String = (
			_override_file_path
			if not _override_file_path.is_empty()
			else ProjectSettings.get_setting(_C.SETTING_FILE_PATH, _C.DEFAULT_FILE_PATH)
		)
		_loggers.append(_DLOGGER_FILE.new(file_path))

	# Fallback for when all are disabled (Quiet)
	if _loggers.is_empty():
		_loggers.append(_DLOGGER_QUIET.new())

	_prefix = get_prefix()
	_min_level = get_min_level()


static func implements_list() -> Array[Script]:
	return [ILogger]


# ------------- [Logging Methods] -------------
## from [ILogger]
func debug(
	msg: String, category: String = "", context: Object = null, _p_prefix: String = ""
) -> void:
	if _min_level > _C.LogLevel.DEBUG:
		return
	for logger: Object in _loggers:
		logger.debug(msg, category, context, _prefix)


## from [ILogger]
func info(
	msg: String, category: String = "", context: Object = null, _p_prefix: String = ""
) -> void:
	if _min_level > _C.LogLevel.INFO:
		return
	for logger: Object in _loggers:
		logger.info(msg, category, context, _prefix)


## from [ILogger]
func warn(
	msg: String, category: String = "", context: Object = null, _p_prefix: String = ""
) -> void:
	if _min_level > _C.LogLevel.WARN:
		return
	for logger: Object in _loggers:
		logger.warn(msg, category, context, _prefix)


## from [ILogger]
func error(
	msg: String, category: String = "", context: Object = null, _p_prefix: String = ""
) -> void:
	if _min_level > _C.LogLevel.ERROR:
		return
	for logger: Object in _loggers:
		logger.error(msg, category, context, _prefix)
