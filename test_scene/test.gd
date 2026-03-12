extends Node2D


func _ready() -> void:
	DLogger.info("Test started! Checking logger functionality.")

	# Test different log levels without category
	_test_log_levels()

	# Test category functionality
	_test_categories()

	# Wait briefly then call from another function to verify stack trace
	await get_tree().create_timer(0.5).timeout
	_check_caller_info()

	DLogger.info("Test complete. Please check the output panel.")


func _test_log_levels() -> void:
	DLogger.debug("This is for debug (gray)")
	DLogger.info("This is general info (cyan, bold)")
	DLogger.warn("This is a warning (yellow, bold, with system notification)")
	DLogger.error("This is an error (red, bold, with system notification)")


func _test_categories() -> void:
	DLogger.info("Spawning player...", "GameLogic")
	DLogger.debug("Handshake successful", "Network")
	DLogger.warn("Heavy frame drop detected", "Performance")
	DLogger.error("Failed to load user profile", "Database")


func _check_caller_info() -> void:
	DLogger.info("Checking line number when called from a different function")
