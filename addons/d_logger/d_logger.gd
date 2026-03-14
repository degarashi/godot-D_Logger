@tool
extends Node

const _C = preload("uid://cwfe01280qmo7")
const _DLOGGER_FILE = preload("uid://b3v27qs0f6a5e")
const _DLOGGER_FULL = preload("uid://bqce6prqiumic")
const _DLOGGER_QUIET = preload("uid://c253k62cylfjd")

# Array to hold multiple loggers
var _loggers: Array[Object] = []

var _first_time := true

# Override values with specific types
var _override_file_path: String = ""
var _override_console_enabled: bool = true
var _override_prefix: String = ""
var _override_min_level: int = -1  # -1 indicates "no override"

# Flag to check if bool/string overrides are active
var _has_console_override: bool = false
var _has_prefix_override: bool = false


func _init(
	file_path: String = "",
	console_enabled: Variant = null,
	prefix_val: Variant = null,
	min_lvl: int = -1
) -> void:
	_override_file_path = file_path

	if console_enabled is bool:
		_override_console_enabled = console_enabled
		_has_console_override = true

	if prefix_val is String:
		_override_prefix = prefix_val
		_has_prefix_override = true

	_override_min_level = min_lvl

	# Force re-setup if already initialized
	_first_time = true
	_setup_logger()


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


	var console_enabled: bool = (
		_override_console_enabled
		if _has_console_override
		else ProjectSettings.get_setting(_C.SETTING_ENABLE, true)
	)

	var file_enabled: bool = ProjectSettings.get_setting(_C.SETTING_ENABLE_FILE, false)

	var prefix_val: String = (
		_override_prefix
		if _has_prefix_override
		else ProjectSettings.get_setting(_C.SETTING_PREFIX, _C.DEFAULT_PREFIX)
	)

	var min_lvl: int = (
		_override_min_level
		if _override_min_level != -1
		else ProjectSettings.get_setting(_C.SETTING_MIN_LEVEL, 0)
	)

	# Retrieve settings with potential overrides
	var is_debug := OS.is_debug_build()

	# Construct console logger
	if is_debug and console_enabled:
		var console_logger := _DLOGGER_FULL.new()
		_configure_logger(console_logger, prefix_val, min_lvl)
		_loggers.append(console_logger)

	# Construct file output logger
	if is_debug and file_enabled:
		var file_path: String = (
			_override_file_path
			if not _override_file_path.is_empty()
			else ProjectSettings.get_setting(_C.SETTING_FILE_PATH, _C.DEFAULT_FILE_PATH)
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
		if logger.min_level <= _C.LogLevel.DEBUG:
			logger.debug(msg, category, context)


func info(msg: Variant, category: String = "", context: Object = null) -> void:
	for logger in _loggers:
		if logger.min_level <= _C.LogLevel.INFO:
			logger.info(msg, category, context)


func warn(msg: Variant, category: String = "", context: Object = null) -> void:
	for logger in _loggers:
		if logger.min_level <= _C.LogLevel.WARN:
			logger.warn(msg, category, context)


func error(msg: Variant, category: String = "", context: Object = null) -> void:
	for logger in _loggers:
		if logger.min_level <= _C.LogLevel.ERROR:
			logger.error(msg, category, context)
