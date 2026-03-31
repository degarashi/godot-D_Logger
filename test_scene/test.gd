extends Node

const DLOGGER = preload("res://addons/d_logger/d_logger.gd")
const _C = preload("uid://cwfe01280qmo7")


func _ready() -> void:
	# Test with default settings (Follows ProjectSettings)
	var logger_default: DLOGGER = DLOGGER.new()
	logger_default.info("Default: Logging info")
	logger_default.warn("Default: Logging warning")

	# Override prefix
	var logger_custom_prefix: DLOGGER = DLOGGER.new("CUSTOM_APP")
	logger_custom_prefix.warn("Custom Prefix: Warning with new prefix")

	# Set log level to DEBUG (All logs should be visible)
	var logger_debug: DLOGGER = DLOGGER.new("DEBUG_TEST", _C.LogLevel.DEBUG)
	logger_debug.debug("Debug: Visible")
	logger_debug.info("Info: Visible")
	logger_debug.warn("Warn: Visible")

	# Set log level to WARN (INFO and below hidden, WARN and above visible)
	var logger_warn_limit: DLOGGER = DLOGGER.new("WARN_LIMIT", _C.LogLevel.WARN)
	logger_warn_limit.info("Warn Limit: Info should NOT be visible")
	logger_warn_limit.warn("Warn Limit: Warning should be visible")
	logger_warn_limit.error("Warn Limit: Error should be visible")

	# Set log level to ERROR (Confirm WARN is hidden)
	var logger_error_only: DLOGGER = DLOGGER.new("ERROR_ONLY", _C.LogLevel.ERROR)
	logger_error_only.warn("Error Only: Warning should NOT be visible")
	logger_error_only.error("Error Only: Error should be visible")

	# Test with console disabled (Nothing should be output)
	var logger_no_console: DLOGGER = DLOGGER.new("SILENT", -1, false)
	logger_no_console.warn("Silent: Warning should NOT appear in console")

	# Test warning with category
	var logger_cat: DLOGGER = DLOGGER.new("CATEGORY_TEST")
	logger_cat.warn("Low memory detected!", "System")
	logger_cat.info("Player spawned at {0}", [Vector2(100, 200)], "Gameplay")
	logger_cat.error("Connection lost", [], "Network")
	logger_cat.debug("Internal AI state: IDLE", [], "Gameplay")

	# Verify stack trace and caller info
	await get_tree().create_timer(0.5).timeout
	_check_caller_info(logger_custom_prefix)

	print("--- Test complete. Please check the output panel above. ---")


func _check_caller_info(p_logger: DLOGGER) -> void:
	p_logger.warn("Checking line number/caller for warning from sub-function")
