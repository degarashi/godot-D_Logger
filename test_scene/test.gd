extends Node2D

const DLOGGER = preload("res://addons/d_logger/d_logger.gd")
var _logger: Node


func _ready() -> void:
	_logger = DLOGGER.new()
	_logger.info("Test started! Checking logger functionality.")

	# Test different log levels without category
	_test_log_levels()

	# Test category functionality
	_test_categories()

	# Wait briefly then call from another function to verify stack trace
	await get_tree().create_timer(0.5).timeout
	_check_caller_info()

	_logger.info("Test complete. Please check the output panel.")


func _test_log_levels() -> void:
	_logger.debug("This is for debug (gray)")
	_logger.info("This is general info (cyan, bold)")
	_logger.warn("This is a warning (yellow, bold, with system notification)")
	_logger.error("This is an error (red, bold, with system notification)")


func _test_categories() -> void:
	_logger.info("Spawning player...", "GameLogic")
	_logger.debug("Handshake successful", "Network")
	_logger.warn("Heavy frame drop detected", "Performance")
	_logger.error("Failed to load user profile", "Database")


func _check_caller_info() -> void:
	_logger.info("Checking line number when called from a different function")
