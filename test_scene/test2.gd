extends Node

# ------------- [Public Variable] -------------
@onready var d_logger_finder: DLoggerFinder = %DLoggerFinder


# ------------- [Callbacks] -------------
func _ready() -> void:
	# Ensure this node processes even when paused
	process_mode = PROCESS_MODE_ALWAYS

	if d_logger_finder:
		DLogger.info("DLoggerFinder detected successfully")
		if d_logger_finder.get_logger():
			DLogger.info("Valid logger instance obtained from DLoggerFinder")

	print("--- Pause on Error Test Scene ---")
	print("Press [SPACE] to trigger an error and test pause functionality.")
	print(
		"Current pause_on_error setting: ",
		ProjectSettings.get_setting(DLoggerConstants.SETTING_PAUSE_ON_ERROR, false)
	)

	# Automatic test after 2 seconds
	await get_tree().create_timer(2.0).timeout
	if not get_tree().paused:
		_run_pause_test()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		if get_tree().paused:
			print("Unpausing...")
			get_tree().paused = false
		else:
			_run_pause_test()


# ------------- [Private Method] -------------
func _run_pause_test() -> void:
	print("\nStarting Pause on Error test...")

	# Force enable the setting for this test
	ProjectSettings.set_setting(DLoggerConstants.SETTING_PAUSE_ON_ERROR, true)

	DLogger.error("Testing Pause on Error! The game tree should pause NOW.")

	if get_tree().paused:
		print("SUCCESS: Game tree is PAUSED.")
	else:
		print("FAILURE: Game tree is NOT paused. (Check if OS.is_debug_build() is true)")
