@tool
extends Node

const _C = preload("uid://cwfe01280qmo7")
const _DLOGGER_FILE = preload("uid://b3v27qs0f6a5e")
const _DLOGGER_FULL = preload("uid://bqce6prqiumic")
const _DLOGGER_QUIET = preload("uid://c253k62cylfjd")
const _DLOGGER_BASE = preload("uid://cbrhmi0wx4qn6")

# Array to hold multiple loggers
var _loggers: Array[Object] = []

var _first_time := true


func _enter_tree() -> void:
	_setup_logger()
	if not ProjectSettings.settings_changed.is_connected(_setup_logger):
		ProjectSettings.settings_changed.connect(_setup_logger)


## Sets up the logger configuration (Factory & Multi-cast)
func _setup_logger() -> void:
	if _first_time:
		_first_time = false
	else:
		return

	_loggers.clear()

	# Retrieve settings
	var is_debug := OS.is_debug_build()
	var console_enabled: bool = ProjectSettings.get_setting(_C.SETTING_ENABLE, true)
	var file_enabled: bool = ProjectSettings.get_setting(_C.SETTING_ENABLE_FILE, false)

	var prefix_val: String = ProjectSettings.get_setting(_C.SETTING_PREFIX, _C.DEFAULT_PREFIX)
	var min_lvl: int = ProjectSettings.get_setting(_C.SETTING_MIN_LEVEL, 0)

	# Construct console logger
	if is_debug and console_enabled:
		var console_logger := _DLOGGER_FULL.new()
		_configure_logger(console_logger, prefix_val, min_lvl)
		_loggers.append(console_logger)

	# Construct file output logger
	if is_debug and file_enabled:
		var file_path: String = ProjectSettings.get_setting(
			_C.SETTING_FILE_PATH, _C.DEFAULT_FILE_PATH
		)
		var file_logger := _DLOGGER_FILE.new(file_path)
		_configure_logger(file_logger, prefix_val, min_lvl)
		_loggers.append(file_logger)

	# Fallback for when all are disabled (Quiet)
	if _loggers.is_empty():
		var quiet_logger := _DLOGGER_QUIET.new()
		_configure_logger(quiet_logger, prefix_val, min_lvl)
		_loggers.append(quiet_logger)


func _configure_logger(logger: Object, p_prefix: String, p_min_lvl: int) -> void:
	logger.prefix = p_prefix
	logger.min_level = p_min_lvl


# ------------- [Logging Methods] -------------
func debug(msg: Variant, category: String = "", context: Object = null) -> void:
	for logger in _loggers:
		if logger.min_level <= _DLOGGER_BASE.LogLevel.DEBUG:
			logger.debug(msg, category, context)


func info(msg: Variant, category: String = "", context: Object = null) -> void:
	for logger in _loggers:
		if logger.min_level <= _DLOGGER_BASE.LogLevel.INFO:
			logger.info(msg, category, context)


func warn(msg: Variant, category: String = "", context: Object = null) -> void:
	for logger in _loggers:
		if logger.min_level <= _DLOGGER_BASE.LogLevel.WARN:
			logger.warn(msg, category, context)


func error(msg: Variant, category: String = "", context: Object = null) -> void:
	for logger in _loggers:
		if logger.min_level <= _DLOGGER_BASE.LogLevel.ERROR:
			logger.error(msg, category, context)
