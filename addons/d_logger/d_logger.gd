@tool
extends Node

# Project Settings paths
const SETTING_ENABLE := "debug/d_logger/enable_log"
const SETTING_PREFIX := "debug/d_logger/prefix"
const SETTING_MIN_LEVEL := "debug/d_logger/min_log_level"

var _logger: DLoggerBase


func _enter_tree() -> void:
	_setup_logger()
	# Listen for setting changes in real-time
	if not ProjectSettings.settings_changed.is_connected(_setup_logger):
		ProjectSettings.settings_changed.connect(_setup_logger)


## Initializes or updates the logger instance based on Project Settings.
func _setup_logger() -> void:
	# Fetch settings with default values
	var is_enabled: bool = ProjectSettings.get_setting(SETTING_ENABLE, true)
	if not OS.is_debug_build():
		is_enabled = false

	var prefix_val: String = ProjectSettings.get_setting(SETTING_PREFIX, "D-Logger")
	var min_lvl: int = ProjectSettings.get_setting(SETTING_MIN_LEVEL, 0)  # Default: DEBUG(0)

	# Clean up old logger instance
	_logger = null

	# Factory Pattern: Switch implementation based on 'is_enabled'
	if is_enabled:
		_logger = DLoggerFull.new()
	else:
		_logger = DLoggerQuiet.new()

	# Inject properties
	_logger.prefix = prefix_val
	_logger.min_level = min_lvl


func debug(msg: Variant, category: String = "") -> void:
	if _logger and _logger.min_level <= DLoggerBase.LogLevel.DEBUG:
		_logger.debug(msg, category)


func info(msg: Variant, category: String = "") -> void:
	if _logger and _logger.min_level <= DLoggerBase.LogLevel.INFO:
		_logger.info(msg, category)


func warn(msg: Variant, category: String = "") -> void:
	# Warnings and Errors are usually not filtered strictly,
	# but we follow the min_level setting here for consistency.
	if _logger and _logger.min_level <= DLoggerBase.LogLevel.WARN:
		_logger.warn(msg, category)


func error(msg: Variant, category: String = "") -> void:
	if _logger and _logger.min_level <= DLoggerBase.LogLevel.ERROR:
		_logger.error(msg, category)
