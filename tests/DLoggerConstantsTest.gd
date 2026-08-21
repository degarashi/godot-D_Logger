class_name DLoggerConstantsTest
extends GdUnitTestSuite

const _CONST = preload("res://addons/d_logger/constants.gd")


# ------------- [LogLevel Enum] -------------
func test_log_level_not_specified() -> void:
	assert_int(_CONST.LogLevel.NOT_SPECIFIED).is_equal(-1)


func test_log_level_debug() -> void:
	assert_int(_CONST.LogLevel.DEBUG).is_equal(0)


func test_log_level_info() -> void:
	assert_int(_CONST.LogLevel.INFO).is_equal(1)


func test_log_level_warn() -> void:
	assert_int(_CONST.LogLevel.WARN).is_equal(2)


func test_log_level_error() -> void:
	assert_int(_CONST.LogLevel.ERROR).is_equal(3)


func test_log_level_ordering() -> void:
	# Verify ordering: DEBUG < INFO < WARN < ERROR
	assert_bool(_CONST.LogLevel.DEBUG < _CONST.LogLevel.INFO)
	assert_bool(_CONST.LogLevel.INFO < _CONST.LogLevel.WARN)
	assert_bool(_CONST.LogLevel.WARN < _CONST.LogLevel.ERROR)


# ------------- [Setting Paths - Project Settings] -------------
func test_setting_prefix() -> void:
	assert_str(_CONST.SETTING_PREFIX).is_equal("debug/d_logger/prefix")


func test_setting_enable_console() -> void:
	assert_str(_CONST.SETTING_ENABLE_CONSOLE).is_equal(
		"debug/d_logger/enable_console_log"
	)


func test_setting_min_level() -> void:
	assert_str(_CONST.SETTING_MIN_LEVEL).is_equal(
		"debug/d_logger/min_log_level"
	)


func test_setting_enable_file() -> void:
	assert_str(_CONST.SETTING_ENABLE_FILE).is_equal(
		"debug/d_logger/enable_file_log"
	)


func test_setting_file_path() -> void:
	assert_str(_CONST.SETTING_FILE_PATH).is_equal(
		"debug/d_logger/log_file_path"
	)


func test_setting_pause_on_error() -> void:
	assert_str(_CONST.SETTING_PAUSE_ON_ERROR).is_equal(
		"debug/d_logger/pause_on_error"
	)


# ------------- [Editor Settings Paths] -------------
func test_editor_setting_enable_console() -> void:
	assert_str(_CONST.EDITOR_SETTING_ENABLE_CONSOLE).is_equal(
		"d_logger/enable_console_log"
	)


func test_editor_setting_min_level() -> void:
	assert_str(_CONST.EDITOR_SETTING_MIN_LEVEL).is_equal(
		"d_logger/min_log_level"
	)


func test_editor_setting_enable_file() -> void:
	assert_str(_CONST.EDITOR_SETTING_ENABLE_FILE).is_equal(
		"d_logger/enable_file_log"
	)


func test_editor_setting_file_path() -> void:
	assert_str(_CONST.EDITOR_SETTING_FILE_PATH).is_equal(
		"d_logger/log_file_path"
	)


func test_editor_setting_auto_activate_panel() -> void:
	assert_str(_CONST.EDITOR_SETTING_AUTO_ACTIVATE_PANEL).is_equal(
		"d_logger/auto_activate_panel"
	)


func test_editor_setting_auto_clear_on_start() -> void:
	assert_str(_CONST.EDITOR_SETTING_AUTO_CLEAR_ON_START).is_equal(
		"d_logger/auto_clear_on_start"
	)


func test_editor_setting_pause_on_error() -> void:
	assert_str(_CONST.EDITOR_SETTING_PAUSE_ON_ERROR).is_equal(
		"d_logger/pause_on_error"
	)


# ------------- [Default Values] -------------
func test_default_prefix() -> void:
	assert_str(_CONST.DEFAULT_PREFIX).is_equal("D-Logger")


func test_default_file_path() -> void:
	assert_str(_CONST.DEFAULT_FILE_PATH).is_equal("user://debug.log")


# ------------- [File Logging] -------------
func test_max_log_file_size() -> void:
	assert_int(_CONST.MAX_LOG_FILE_SIZE).is_equal(10 * 1024 * 1024)


func test_log_file_backup_suffix() -> void:
	assert_str(_CONST.LOG_FILE_BACKUP_SUFFIX).is_equal(".1")


# ------------- [Autoload Info] -------------
func test_autoload_name() -> void:
	assert_str(_CONST.AUTOLOAD_NAME).is_equal("DLogger")


func test_autoload_path() -> void:
	assert_str(_CONST.AUTOLOAD_PATH).is_equal(
		"res://addons/d_logger/d_logger_node.tscn"
	)


# ------------- [Log Level Labels] -------------
func test_min_level_hint_string() -> void:
	assert_str(_CONST.MIN_LEVEL_HINT_STRING).is_equal(
		"DEBUG:0,INFO:1,WARN:2,ERROR:3"
	)


func test_log_level_labels_debug() -> void:
	assert_str(_CONST.LOG_LEVEL_LABELS[0]).is_equal("DEBUG")


func test_log_level_labels_info() -> void:
	assert_str(_CONST.LOG_LEVEL_LABELS[1]).is_equal("INFO")


func test_log_level_labels_warn() -> void:
	assert_str(_CONST.LOG_LEVEL_LABELS[2]).is_equal("WARN")


func test_log_level_labels_error() -> void:
	assert_str(_CONST.LOG_LEVEL_LABELS[3]).is_equal("ERROR")


func test_log_level_labels_has_all_levels() -> void:
	assert_int(_CONST.LOG_LEVEL_LABELS.size()).is_equal(4)
	assert_bool(_CONST.LOG_LEVEL_LABELS.has(0))
	assert_bool(_CONST.LOG_LEVEL_LABELS.has(1))
	assert_bool(_CONST.LOG_LEVEL_LABELS.has(2))
	assert_bool(_CONST.LOG_LEVEL_LABELS.has(3))


# ------------- [Consistency Checks] -------------
func test_runtime_settings_match_editor_settings_console() -> void:
	# Runtime and editor setting names should match (except prefix)
	# Editor: d_logger/enable_console_log
	# Runtime: debug/d_logger/enable_console_log
	assert_str(_CONST.EDITOR_SETTING_ENABLE_CONSOLE).is_equal(
		_CONST.SETTING_ENABLE_CONSOLE.replace("debug/", "")
	)


func test_runtime_settings_match_editor_settings_min_level() -> void:
	assert_str(_CONST.EDITOR_SETTING_MIN_LEVEL).is_equal(
		_CONST.SETTING_MIN_LEVEL.replace("debug/", "")
	)


func test_runtime_settings_match_editor_settings_enable_file() -> void:
	assert_str(_CONST.EDITOR_SETTING_ENABLE_FILE).is_equal(
		_CONST.SETTING_ENABLE_FILE.replace("debug/", "")
	)


func test_runtime_settings_match_editor_settings_file_path() -> void:
	assert_str(_CONST.EDITOR_SETTING_FILE_PATH).is_equal(
		_CONST.SETTING_FILE_PATH.replace("debug/", "")
	)


func test_runtime_settings_match_editor_settings_pause_on_error() -> void:
	assert_str(_CONST.EDITOR_SETTING_PAUSE_ON_ERROR).is_equal(
		_CONST.SETTING_PAUSE_ON_ERROR.replace("debug/", "")
	)
