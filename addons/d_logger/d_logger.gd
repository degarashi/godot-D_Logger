@tool
extends Node

# Project Settings paths
const SETTING_ENABLE := "debug/d_logger/enable_log"
const SETTING_PREFIX := "debug/d_logger/prefix"

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
	var prefix_val: String = ProjectSettings.get_setting(SETTING_PREFIX, "D-Logger")

	# Clean up old logger instance if it exists to prevent memory leaks
	_logger = null

	# Factory Pattern: Switch implementation based on 'is_enabled'
	if is_enabled:
		_logger = DLoggerFull.new()
	else:
		_logger = DLoggerQuiet.new()

	# Inject the custom prefix into the logger instance
	_logger.prefix = prefix_val


func debug(msg: Variant) -> void:
	if _logger:
		_logger.debug(msg)


func info(msg: Variant) -> void:
	if _logger:
		_logger.info(msg)


func warn(msg: Variant) -> void:
	if _logger:
		_logger.warn(msg)


func error(msg: Variant) -> void:
	if _logger:
		_logger.error(msg)
