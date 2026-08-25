extends Node

const DLOGGER = preload("res://addons/d_logger/d_logger.gd")
const _C = preload("uid://cwfe01280qmo7")

# Log-flood settings: after the feature smoke tests, the scene streams many
# log lines so manual checks (drag-select latency, stacking, trimming) can
# happen against a realistically full panel (~thousands of rows).
# Override the total with the D_LOGGER_FLOOD_COUNT environment variable.
const DEFAULT_FLOOD_COUNT := 2000
const FLOOD_BATCH_SIZE := 25
const FLOOD_INTERVAL_SECONDS := 0.02

# Class-level variable
var logger_custom_prefix: DLOGGER

# Flood state
var _flood_logger: DLOGGER
var _flood_sent := 0
var _flood_target := 0


# ------------- [Public Method] -------------
func _ready() -> void:
	# Run tests: default settings logging first
	_test_default_settings()
	_test_custom_prefix()
	_test_log_level_debug()
	_test_log_level_warn()
	_test_log_level_error()
	_test_console_disabled()
	_test_with_category()
	_test_with_multiple_tags()
	_test_rainbow_brackets()
	_test_log_stacking()
	_test_caller_info()


# ------------- [Private Method] -------------
func _test_default_settings() -> void:
	# Logging test with default settings
	var logger_default := DLOGGER.new()
	logger_default.info("Default: Logging info")
	logger_default.warn("Default: Logging warning")


func _test_custom_prefix() -> void:
	# Custom prefix test
	logger_custom_prefix = DLOGGER.new("CUSTOM_APP")
	logger_custom_prefix.warn("Custom Prefix: Warning with new prefix")


func _test_log_level_debug() -> void:
	# Log level set to DEBUG (all logs visible)
	var logger_debug := DLOGGER.new("DEBUG_TEST", _C.LogLevel.DEBUG)
	logger_debug.debug("Debug: Visible")
	logger_debug.info("Info: Visible")
	logger_debug.warn("Warn: Visible")


func _test_log_level_warn() -> void:
	# Log level set to WARN (DEBUG/INFO hidden)
	var logger_warn_limit := DLOGGER.new("WARN_LIMIT", _C.LogLevel.WARN)
	logger_warn_limit.info("Warn Limit: Info should NOT be visible")
	logger_warn_limit.warn("Warn Limit: Warning should be visible")
	logger_warn_limit.error("Warn Limit: Error should be visible")


func _test_log_level_error() -> void:
	# Log level set to ERROR (WARN hidden)
	var logger_error_only := DLOGGER.new("ERROR_ONLY", _C.LogLevel.ERROR)
	logger_error_only.warn("Error Only: Warning should NOT be visible")
	logger_error_only.error("Error Only: Error should be visible")


func _test_console_disabled() -> void:
	# Console output disabled (no logs emitted)
	var logger_no_console := DLOGGER.new("SILENT", -1, false)
	logger_no_console.warn("Silent: Warning should NOT appear in console")


func _test_with_category() -> void:
	# Warnings with categories
	var logger_cat := DLOGGER.new("CATEGORY_TEST")
	logger_cat.warn("Low memory detected!", [], "System")
	logger_cat.info("Player spawned at {0}", [Vector2(100, 200)], "Gameplay")
	logger_cat.error("Connection lost", [], "Network")
	logger_cat.debug("Internal AI state: IDLE", [], "Gameplay")


func _test_with_multiple_tags() -> void:
	# Multiple tags
	var logger_tags := DLOGGER.new("TAG_TEST")
	logger_tags.info("Multiple tags: AI and Combat", [], "AI|Combat")
	logger_tags.info("Multiple tags: Network and Player", [], "Network|Player")
	logger_tags.info("Single tag: Player", [], "Player")


func _test_rainbow_brackets() -> void:
	# Rainbow brackets: color varies by nesting depth
	# Depth-4 sample quotes its keys so no unresolved-placeholder warning fires
	var logger_rainbow := DLOGGER.new("RAINBOW_TEST")
	logger_rainbow.info("Depth 1: position (100, 200)")
	logger_rainbow.info("Depth 2: inventory [potion (x3), sword (dmg 12)]")
	logger_rainbow.info(
		'Depth 4: {"save": {"pos": [1, (2)], "bag": [{"id": 0}]}}'
	)


func _test_log_stacking() -> void:
	# Log stacking test
	print("Testing Log Stacking (Check Editor Panel for (x10) indicator)...")
	var logger_stack := DLOGGER.new("STACK_TEST")
	for i in range(10):
		logger_stack.info("This is a repeated message")
	logger_stack.info("A different message")
	for i in range(5):
		logger_stack.info("This is a repeated message")  # new stack starts because the previous message differs


func _test_caller_info() -> void:
	# Verify caller info
	await get_tree().create_timer(0.5).timeout
	_check_caller_info(logger_custom_prefix)
	_start_log_flood()


func _check_caller_info(p_logger: DLOGGER) -> void:
	p_logger.warn("Checking line number/caller for warning from sub-function")


# ------------- [Log Flood] -------------
## Streams a large volume of logs over several seconds so the editor panel
## fills up like in real use. Paced via timers (not one blocking loop) so
## stacking/rebuild coalescing behaves as it would under live logging.
func _start_log_flood() -> void:
	_flood_logger = DLOGGER.new("FLOOD")
	var env_count := OS.get_environment("D_LOGGER_FLOOD_COUNT")
	_flood_target = (
		env_count.to_int()
		if env_count.is_valid_int() and env_count.to_int() > 0
		else DEFAULT_FLOOD_COUNT
	)
	print(
		(
			"Log flood: emitting %d lines (%d per tick, %.0fs)..."
			% [
				_flood_target,
				FLOOD_BATCH_SIZE,
				_flood_target / float(FLOOD_BATCH_SIZE) * FLOOD_INTERVAL_SECONDS
			]
		)
	)
	_emit_flood_batch()


func _emit_flood_batch() -> void:
	for i in range(FLOOD_BATCH_SIZE):
		if _flood_sent >= _flood_target:
			print("Log flood done: %d lines emitted." % _flood_sent)
			return
		_emit_flood_line(_flood_sent)
		_flood_sent += 1
	if _flood_sent % 500 == 0:
		print("Log flood progress: %d / %d" % [_flood_sent, _flood_target])
	await get_tree().create_timer(FLOOD_INTERVAL_SECONDS).timeout
	_emit_flood_batch()


## Cycles through level/category/shape variants so the panel gets a mix of
## colors, filter tags, stacked counts and long wrappable lines.
func _emit_flood_line(index: int) -> void:
	match index % 8:
		0:
			_flood_logger.debug(
				"Flood {0}: routine heartbeat frame={1}",
				[index, Engine.get_frames_drawn()]
			)
		1:
			_flood_logger.info(
				"Player pos ({0}, {1}) inventory [potion (x{2}), sword]",
				[index % 800, index % 600, index % 9 + 1]
			)
		2:
			_flood_logger.warn(
				"Slow frame detected: {0} ms", [(index % 40) + 16]
			)
		3:
			# Repeats only every other batch: keeps stacks short enough to
			# still exercise both append and stacked-rebuild paths.
			_flood_logger.info("Repeated stackable message")
		4:
			_flood_logger.error(
				"Connection lost to server shard-{0}", [index % 12]
			)
		5:
			_flood_logger.info(
				'Structured payload {"pos": [{0}, {1}], "bag": [{"id": {2}}]}',
				[index % 100, index % 50, index % 5]
			)
		6:
			_flood_logger.info(
				"Long line {0}: %s (end of long line)" % "x".repeat(160),
				[index]
			)
		7:
			_flood_logger.info(
				"Flood {0}: multi-tag message", [index], "AI|Combat"
			)
