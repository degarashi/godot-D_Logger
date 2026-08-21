extends Node

# ------------- [Constants] -------------
const TEST_DELAY = 2.0
const SPACE_KEY = KEY_SPACE

# ------------- [Private Variable] -------------
var is_test_running := false

# ------------- [Exports] -------------
@onready var d_logger_finder: DLoggerFinder = %DLoggerFinder


# ------------- [Callbacks] -------------
func _ready() -> void:
	# Ensure this node processes even when the tree is paused
	process_mode = PROCESS_MODE_ALWAYS

	if d_logger_finder:
		_on_d_logger_finder_detected()

	# Start automatic test after delay
	await get_tree().create_timer(TEST_DELAY).timeout
	if not get_tree().paused:
		_run_pause_test()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == SPACE_KEY:
		if get_tree().paused:
			_unpause_tree()
		else:
			_run_pause_test()


# ------------- [Private Method] -------------
func _on_d_logger_finder_detected() -> void:
	# Confirm DLoggerFinder detection
	DLogger.info("DLoggerFinder detected successfully")
	if d_logger_finder.get_logger():
		DLogger.info("Valid logger instance obtained from DLoggerFinder")

	DLogger.info("--- Pause on Error Test Scene ---")
	DLogger.info(
		"Press [SPACE] to trigger an error and test pause functionality."
	)
	DLogger.info(
		"Current pause_on_error setting: ",
		ProjectSettings.get_setting(
			DLoggerConstants.SETTING_PAUSE_ON_ERROR, false
		)
	)


func _unpause_tree() -> void:
	# Resume the game tree
	DLogger.info("Unpausing...")
	get_tree().paused = false


func _run_pause_test() -> void:
	# Execute pause test
	if is_test_running:
		return

	is_test_running = true
	DLogger.info("Starting Pause on Error test...")

	# Force enable the setting for testing
	ProjectSettings.set_setting(DLoggerConstants.SETTING_PAUSE_ON_ERROR, true)

	DLogger.error("Testing Pause on Error! The game tree should pause NOW.")

	if get_tree().paused:
		DLogger.info("SUCCESS: Game tree is PAUSED.")
	else:
		(
			DLogger
			. info(
				"FAILURE: Game tree is NOT paused. (Check if OS.is_debug_build() is true)"
			)
		)

	is_test_running = false
